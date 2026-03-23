import os
import asyncio
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Checkbox, Button, Label, Log
from textual.containers import VerticalScroll, Center
from scanner import prepare_installation_list

class MinstallApp(App):
    """Приложение MInstAll TUI с выбором программ."""
    
    # Обновляем CSS: теперь у нас есть список программ (сверху) и лог (снизу),
    # каждый занимает равную часть экрана (height: 1fr).
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
        """Метод compose отвечает за добавление виджетов на экран."""
        yield Header(show_clock=True)
        
        # Основной блок со списком (с прокруткой)
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

        # Виджет лога для отображения процесса установки
        yield Log(id="log-view")

        # Нижняя панель с кнопкой установки
        with Center(id="action-panel"):
            yield Button("Установить выбранное", variant="success", id="install-btn")
            
        yield Footer()

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        """Этот метод вызывается при нажатии на кнопку. Он асинхронный, чтобы не вешать UI."""
        if event.button.id == "install-btn":
            button = event.button
            log_widget = self.query_one("#log-view", Log)
            
            # Блокируем кнопку на время установки
            button.disabled = True
            button.label = "Идет установка..."
            log_widget.clear()
            log_widget.write_line("=== Начало процесса установки ===")

            # Собираем ID всех выбранных программ из чекбоксов
            selected_ids = []
            for checkbox in self.query(Checkbox):
                if checkbox.value and checkbox.id and checkbox.id.startswith("prog_"):
                    # Достаем id из строки вида "prog_12"
                    prog_id = checkbox.id.split("_")[1]
                    selected_ids.append(prog_id)

            if not selected_ids:
                log_widget.write_line("Ошибка: Ни одной программы не выбрано!")
                button.disabled = False
                button.label = "Установить выбранное"
                return

            # Проходим по нашему списку программ
            for prog in self.programs:
                if str(prog["id"]) in selected_ids:
                    log_widget.write_line(f"\n[ОЖИДАНИЕ] Подготовка: {prog['name']}...")
                    
                    # Формируем строку команды, которая потом будет использоваться в Windows
                    command = f'"{prog["real_path"]}" {prog["flags"]}'
                    log_widget.write_line(f"[СИМУЛЯЦИЯ КОМАНДЫ] Выполняем: {command}")
                    
                    # Имитируем установку (пауза 2 секунды)
                    await asyncio.sleep(2.0)
                    
                    log_widget.write_line(f"[УСПЕШНО] {prog['name']} установлена!")

            log_widget.write_line("\n=== Установка всех выбранных программ завершена! ===")
            
            # Разблокируем кнопку на случай, если захочется запустить снова
            button.disabled = False
            button.label = "Установка завершена (повторить?)"

if __name__ == "__main__":
    app = MinstallApp()
    app.run()