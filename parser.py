import configparser
import os
from typing import List, Dict

def parse_ini_file(ini_path: str, base_dir: str = ".") -> List[Dict[str, str]]:
    """
    Парсит INI-файл конфигурации MInstAll и возвращает список программ для установки.
    
    :param ini_path: Путь к файлу конфигурации (например, 'minst.ini')
    :param base_dir: Базовая директория, на которую заменяется макрос {Patch}
    :return: Список словарей с ключами id, name, exe_path, flags, group.
    """
    # Отключаем interpolation, чтобы configparser не ругался на символы % в путях
    config = configparser.ConfigParser(interpolation=None, strict=False)
    
    # Пытаемся прочитать файл с разными популярными кодировками
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
        # Секции с программами обычно называются числами или точно содержат ключ Patch
        if section.isdigit() or ('Patch' in config[section] and 'Name' in config[section]):
            name = config[section].get('Name', f"Program_{section}")
            patch_path = config[section].get('Patch', '')
            flags = config[section].get('Key', '')
            group = config[section].get('Group', '0')
            
            if patch_path:
                # Заменяем макрос {Patch} на базовую директорию
                # Также заменяем обратные слеши на разделитель текущей ОС (полезно при разработке на Linux)
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

# Пример использования (можно запустить файл напрямую для проверки)
if __name__ == "__main__":
    # Если в текущей папке есть minst.ini, он его прочитает и выведет первые 3 программы
    if os.path.exists("minst.ini"):
        progs = parse_ini_file("minst.ini")
        for p in progs[:3]:
            print(p)
    else:
        print("Файл minst.ini не найден для тестирования.")