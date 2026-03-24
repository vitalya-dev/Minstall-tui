import os
import time
import argparse
import subprocess
import configparser
from typing import List, Dict, Any
from textual import work
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Checkbox, Button, Label, Log
from textual.containers import VerticalScroll, Center

import argparse

def parse_ini_file(ini_path: str, base_dir: str = ".") -> List[Dict[str, Any]]:
    """
    Парсит INI-файл конфигурации MInstAll и возвращает список программ для установки.
    """
    config = configparser.ConfigParser(interpolation=None, strict=False)
    
    parsed = False
    for encoding in ['utf-8-sig', 'utf-16', 'cp1251']:
        try:
            config.read(ini_path, encoding=encoding)
            parsed = True
            break
        except UnicodeDecodeError:
            continue
            
    if not parsed:
        print(f"Не удалось прочитать файл {ini_path}. Проверьте кодировку.")
        return []

    programs = []
    
    for section in config.sections():
        if section.isdigit() or ('Patch' in config[section] and 'Name' in config[section]):
            name = config[section].get('Name', f"Program_{section}")
            patch_path = config[section].get('Patch', '')
            flags = config[section].get('Key', '')
            group = config[section].get('Group', '0')
            
            if patch_path:
                clean_path = patch_path.replace('{Patch}', base_dir).replace('\\', os.sep)
                exe_path = os.path.normpath(clean_path)
                
                programs.append({
                    "id": section,
                    "name": name,
                    "exe_path": exe_path,
                    "flags": flags,
                    "group": group
                })
                
    return programs

def prepare_installation_list(ini_path: str, base_dir: str = ".") -> List[Dict[str, Any]]:
    """
    Получает список программ из INI-файла и сопоставляет их с реальными .exe файлами 
    в папке со скриптом.
    """
    programs = parse_ini_file(ini_path, base_dir)
    available_programs = []

    local_files = [f.lower() for f in os.listdir(base_dir) if f.lower().endswith('.exe')]

    for prog in programs:
        exe_path = prog.get("exe_path", "")
        if not exe_path:
            continue
            
        file_name = os.path.basename(exe_path)
        
        if file_name.lower() in local_files:
            prog["exists"] = True
            prog["real_path"] = os.path.join(base_dir, file_name)
            available_programs.append(prog)

    return available_programs

class MinstallApp(App):
    """Приложение MInstAll TUI с выбором программ."""
    
    # Стилизация под Far Manager: синий фон, двойные бирюзовые рамки
    CSS = """
    Screen {
        background: #0000AA;
        color: #E0E0E0;
    }
    #program-list {
        height: 1fr;
        border: double #00FFFF;
        background: #0000AA;
        margin: 1 2;
        padding: 1;
    }
    #log-view {
        height: 1fr;
        border: double #00FFFF;
        background: #0000AA;
        margin: 0 2 1 2;
    }
    #action-panel {
        height: auto;
        align: center middle;
        margin-bottom: 1;
    }
    Button {
        background: #00AAAA;
        color: white;
        border: none;
    }
    Button:focus {
        background: #00FFFF;
        color: black;
        text-style: bold;
    }
    Checkbox {
        color: #00FFFF;
    }
    Checkbox:focus {
        background: #00AAAA;
        color: white;
    }
    *:focus {
        outline: none;
    }
    """

    BINDINGS = [
        ("q", "quit", "Выход")
    ]

    def __init__(self, debug_mode: bool = False):
        super().__init__()
        # Возвращаем темную тему как базовую, чтобы цвета лучше ложились
        self.theme = "textual-dark"
        
        self.debug_mode = debug_mode
        ini_path = "minst.ini"
        if os.path.exists(ini_path):
            self.programs = prepare_installation_list(ini_path)
        else:
            self.programs = []

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        
        with VerticalScroll(id="program-list"):
            if not self.programs:
                yield Label("Файл minst.ini не найден или в папке нет подходящих .exe файлов.")
            else:
                for prog in self.programs:
                    yield Checkbox(
                        f"{prog['name']} (Ключи: {prog.get('flags', 'нет')})", 
                        value=True, 
                        id=f"prog_{prog['id']}"
                    )

        yield Log(id="log-view")

        with Center(id="action-panel"):
            yield Button("Установить выбранное", variant="success", id="install-btn")
            
        yield Footer()

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        """Обрабатывает нажатие кнопки в главном потоке интерфейса."""
        if event.button.id == "install-btn":
            button = event.button
            log_widget = self.query_one("#log-view", Log)
            
            # Собираем ID всех выбранных программ
            selected_ids = []
            for checkbox in self.query(Checkbox):
                if checkbox.value and checkbox.id and checkbox.id.startswith("prog_"):
                    prog_id = checkbox.id.split("_")[1]
                    selected_ids.append(prog_id)

            if not selected_ids:
                log_widget.write_line("Ошибка: Ни одной программы не выбрано!")
                return

            # Блокируем кнопку
            button.disabled = True
            button.label = "Идет установка..."
            log_widget.clear()
            
            # Запускаем тяжелую работу в отдельном фоновом потоке!
            self.run_installation(selected_ids)

    @work(thread=True)
    def run_installation(self, selected_ids: list) -> None:
        """
        Эта функция работает в фоновом потоке. 
        Она не блокирует интерфейс, и скролл будет работать плавно.
        """
        log_widget = self.query_one("#log-view", Log)
        
        # Вспомогательная функция для безопасного вывода текста из фонового потока в UI
        def log_msg(text: str):
            self.call_from_thread(log_widget.write_line, text)
            
        mode_text = "[DEBUG РЕЖИМ]" if self.debug_mode else "[РЕАЛЬНАЯ УСТАНОВКА]"
        log_msg(f"=== Начало процесса установки {mode_text} ===")

        for prog in self.programs:
            if str(prog["id"]) in selected_ids:
                log_msg(f"\n[ОЖИДАНИЕ] Подготовка: {prog['name']}...")
                command = f'"{prog["real_path"]}" {prog["flags"]}'
                
                if self.debug_mode:
                    log_msg(f"[СИМУЛЯЦИЯ] Выполняем: {command}")
                    # Используем обычный синхронный sleep, так как мы в отдельном потоке
                    time.sleep(2.0) 
                    log_msg(f"[ЗАВЕРШЕНО] {prog['name']} (симуляция завершена)")
                else:
                    log_msg(f"[ЗАПУСК] Выполняем: {command}")
                    # Используем стандартный синхронный subprocess
                    try:
                        process = subprocess.run(command, shell=True, capture_output=True)
                        log_msg(f"[ЗАВЕРШЕНО] {prog['name']} (Код: {process.returncode})")
                    except Exception as e:
                        log_msg(f"[ОШИБКА] Не удалось запустить {prog['name']}: {e}")

        log_msg("\n=== Установка всех выбранных программ завершена! ===")
        
        # Вспомогательная функция для возврата кнопки в исходное состояние
        def reset_button():
            btn = self.query_one("#install-btn", Button)
            btn.disabled = False
            btn.label = "Установка завершена (повторить?)"
            
        # Возвращаем UI в исходное состояние
        self.call_from_thread(reset_button)
        
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MInstAll TUI на Python")
    parser.add_argument("--debug", action="store_true", help="Запуск в режиме симуляции установки")
    args = parser.parse_args()

    app = MinstallApp(debug_mode=args.debug)
    app.run()