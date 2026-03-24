import os
import argparse
import configparser
import subprocess
import time
from typing import List, Dict, Any

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




def main():
    """
    Главная функция CLI-версии MInstAll.
    Сканирует ini-файл и выводит список найденных программ.
    """
    parser = argparse.ArgumentParser(description="MInstAll CLI на Python")
    parser.add_argument("--debug", action="store_true", help="Запуск в режиме симуляции установки")
    args = parser.parse_args()

    print("=" * 50)
    print("=== MInstAll Автоматическая установка ===")
    print(f"=== Режим: {'СИМУЛЯЦИЯ (DEBUG)' if args.debug else 'РЕАЛЬНАЯ УСТАНОВКА'} ===")
    print("=" * 50)

    ini_path = "minst.ini"
    if not os.path.exists(ini_path):
        print(f"\n[ОШИБКА] Файл {ini_path} не найден в текущей папке!")
        return

    print(f"\nСканирование {ini_path} и поиск .exe файлов...")
    programs = prepare_installation_list(ini_path)

    if not programs:
        print("\n[ВНИМАНИЕ] Подходящих .exe файлов для установки не найдено.")
        return

    print(f"\nГотово к установке программ: {len(programs)}")
    for i, prog in enumerate(programs, 1):
        file_name = os.path.basename(prog["real_path"])
        print(f" {i}. {prog['name']} (Файл: {file_name})")
        
    # Здесь в будущем будет вызов функции установки
    print("\nПодготовка завершена...")