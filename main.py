from textual.app import App, ComposeResult
from textual.widgets import Header, Footer

class MinstallApp(App):
    """Базовое приложение MInstAll TUI."""
    
    # Назначаем горячие клавиши. В данном случае "q" для выхода.
    BINDINGS = [
        ("q", "quit", "Выход")
    ]

    def compose(self) -> ComposeResult:
        """Метод compose отвечает за добавление виджетов на экран."""
        yield Header(show_clock=True)
        yield Footer()

if __name__ == "__main__":
    app = MinstallApp()
    app.run()