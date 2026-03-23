import configparser
import os
from typing import List, Dict, Any

def parse_ini_file(ini_path: str, base_dir: str = ".") -> List[Dict[str, Any]]:
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