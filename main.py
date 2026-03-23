import os
import asyncio
import configparser
from typing import List, Dict, Any
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Checkbox, Button, Label, Log
from textual.containers import VerticalScroll, Center

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
    
    CSS = """
    #program-list {
        height: 1fr;
        border: solid green;
        margin: 1 2;
        padding: 1;
    }
    #log-view {
        height: 1fr;
        border: solid blue;
        margin: 0 2 1 2;
    }
    #action-panel {
        height: auto;
        align: center middle;
        margin-bottom: 1;
    }
    """

    BINDINGS = [
        ("q", "quit", "Выход")
    ]

    def __init__(self):
        super().__init__()
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
        if event.button.id == "install-btn":
            button = event.button
            log_widget = self.query_one("#log-view", Log)
            
            button.disabled = True
            button.label = "Идет установка..."
            log_widget.clear()
            log_widget.write_line("=== Начало процесса установки ===")

            selected_ids = []
            for checkbox in self.query(Checkbox):
                if checkbox.value and checkbox.id and checkbox.id.startswith("prog_"):
                    prog_id = checkbox.id.split("_")[1]
                    selected_ids.append(prog_id)

            if not selected_ids:
                log_widget.write_line("Ошибка: Ни одной программы не выбрано!")
                button.disabled = False
                button.label = "Установить выбранное"
                return

            for prog in self.programs:
                if str(prog["id"]) in selected_ids:
                    log_widget.write_line(f"\n[ОЖИДАНИЕ] Подготовка: {prog['name']}...")
                    
                    command = f'"{prog["real_path"]}" {prog["flags"]}'
                    log_widget.write_line(f"[СИМУЛЯЦИЯ КОМАНДЫ] Выполняем: {command}")
                    
                    await asyncio.sleep(2.0)
                    
                    log_widget.write_line(f"[УСПЕШНО] {prog['name']} установлена!")

            log_widget.write_line("\n=== Установка всех выбранных программ завершена! ===")
            
            button.disabled = False
            button.label = "Установка завершена (повторить?)"

if __name__ == "__main__":
    app = MinstallApp()
    app.run()