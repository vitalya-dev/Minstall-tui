import os
from typing import List, Dict, Any
from parser import parse_ini_file

def prepare_installation_list(ini_path: str, base_dir: str = ".") -> List[Dict[str, Any]]:
    """
    Получает список программ из INI-файла и сопоставляет их с реальными .exe файлами 
    в папке со скриптом.
    Возвращает список словарей программ, которые реально найдены в папке.
    """
    programs = parse_ini_file(ini_path, base_dir)
    available_programs = []

    # Получаем список всех .exe файлов в нашей папке (в нижнем регистре для надежности)
    local_files = [f.lower() for f in os.listdir(base_dir) if f.lower().endswith('.exe')]

    for prog in programs:
        exe_path = prog.get("exe_path", "")
        if not exe_path:
            continue
            
        # Извлекаем только имя файла
        file_name = os.path.basename(exe_path)
        
        # Проверяем, есть ли такой файл среди тех, что лежат рядом со скриптом
        if file_name.lower() in local_files:
            prog["exists"] = True
            prog["real_path"] = os.path.join(base_dir, file_name)
            available_programs.append(prog)

    return available_programs