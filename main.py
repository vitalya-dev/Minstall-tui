import os
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Checkbox, Button, Label
from textual.containers import VerticalScroll, Center
from scanner import prepare_installation_list

class MinstallApp(App):
    """Приложение MInstAll TUI с выбором программ."""
    
    # Немного CSS для красоты, чтобы список программ занимал основное место,
    # а кнопка была красиво отцентрирована внизу.
    CSS = """
    #program-list {
        height: 1fr;
        border: solid green;
        margin: 1 2;
        padding: 1;
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
        # При запуске приложения сразу сканируем файлы
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
                    # Создаем чекбокс. По умолчанию он будет включен (value=True)
                    # В id чекбокса мы прячем уникальный id программы из ini файла
                    yield Checkbox(
                        f"{prog['name']} (Ключи: {prog.get('flags', 'нет')})", 
                        value=True, 
                        id=f"prog_{prog['id']}"
                    )

        # Нижняя панель с кнопкой установки
        with Center(id="action-panel"):
            yield Button("Установить выбранное", variant="success", id="install-btn")
            
        yield Footer()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Этот метод вызывается при нажатии на любую кнопку."""
        if event.button.id == "install-btn":
            # Пока мы просто меняем текст кнопки, чтобы проверить, что нажатие работает.
            # Саму логику установки мы добавим на следующем шаге.
            event.button.label = "Подготовка к установке..."

if __name__ == "__main__":
    app = MinstallApp()
    app.run()