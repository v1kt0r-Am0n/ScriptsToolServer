import os
import pyodbc
import time
from datetime import datetime
import getpass
import colorama
from colorama import Fore, Style

class SQLConsole:
    def __init__(self):
        self.connection = None
        self.scripts_dir = "scripts"
        self.ensure_scripts_directory()
        self.available_scripts = self.load_scripts()
        colorama.init()

    def show_banner(self):
        """Muestra el banner personalizado"""
        banner = f"""
{Fore.CYAN}╔════════════════════════════════════════════════════════════╗
║                                                                ║
║  {Fore.YELLOW}██╗   ██╗██╗██╗  ██╗████████╗ ██████╗ ██████╗{Fore.CYAN}        ║
║  {Fore.YELLOW}██║   ██║██║██║ ██╔╝╚══██╔══╝██╔═══██╗██╔══██╗{Fore.CYAN}       ║
║  {Fore.YELLOW}██║   ██║██║█████╔╝    ██║   ██║   ██║██████╔╝{Fore.CYAN}       ║
║  {Fore.YELLOW}╚██╗ ██╔╝██║██╔═██╗    ██║   ██║   ██║██╔══██╗{Fore.CYAN}       ║
║  {Fore.YELLOW} ╚████╔╝ ██║██║  ██╗   ██║   ╚██████╔╝██║  ██║{Fore.CYAN}       ║
║  {Fore.YELLOW}  ╚═══╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝{Fore.CYAN}       ║
║                                                                ║
║  {Fore.GREEN}SQL Server Administration Console v1.0{Fore.CYAN}                ║
║  {Fore.MAGENTA}Desarrollado por: v1kt0r-Am0n{Fore.CYAN}                        ║
╚════════════════════════════════════════════════════════════╝{Style.RESET_ALL}
"""
        print(banner)

    def ensure_scripts_directory(self):
        """Asegura que el directorio de scripts existe"""
        if not os.path.exists(self.scripts_dir):
            os.makedirs(self.scripts_dir)
            print(f"{Fore.YELLOW}Directorio {self.scripts_dir} creado.{Style.RESET_ALL}")

    def load_scripts(self):
        """Carga los scripts SQL disponibles"""
        scripts = {}
        for file in os.listdir(self.scripts_dir):
            if file.endswith('.sql'):
                scripts[file] = os.path.join(self.scripts_dir, file)
        return scripts

    def connect_to_sql_server(self):
        """Establece conexión con SQL Server"""
        print(f"\n{Fore.CYAN}=== Configuración de Conexión ==={Style.RESET_ALL}")
        server = input(f"{Fore.GREEN}Servidor: {Style.RESET_ALL}")
        database = input(f"{Fore.GREEN}Base de datos: {Style.RESET_ALL}")
        username = input(f"{Fore.GREEN}Usuario: {Style.RESET_ALL}")
        password = getpass.getpass(f"{Fore.GREEN}Contraseña: {Style.RESET_ALL}")

        try:
            connection_string = (
                f"DRIVER={{SQL Server}};"
                f"SERVER={server};"
                f"DATABASE={database};"
                f"UID={username};"
                f"PWD={password}"
            )
            self.connection = pyodbc.connect(connection_string)
            print(f"\n{Fore.GREEN}✓ Conexión exitosa!{Style.RESET_ALL}")
            return True
        except Exception as e:
            print(f"\n{Fore.RED}✗ Error de conexión: {str(e)}{Style.RESET_ALL}")
            return False

    def execute_script(self, script_path):
        """Ejecuta un script SQL"""
        try:
            with open(script_path, 'r', encoding='utf-8') as file:
                sql_script = file.read()

            cursor = self.connection.cursor()
            cursor.execute(sql_script)
            
            # Mostrar resultados
            columns = [column[0] for column in cursor.description]
            print(f"\n{Fore.CYAN}Resultados:{Style.RESET_ALL}")
            print(f"{Fore.CYAN}{'-' * 80}{Style.RESET_ALL}")
            for row in cursor.fetchall():
                print(dict(zip(columns, row)))
            print(f"{Fore.CYAN}{'-' * 80}{Style.RESET_ALL}")

            cursor.close()
            return True
        except Exception as e:
            print(f"\n{Fore.RED}✗ Error al ejecutar script: {str(e)}{Style.RESET_ALL}")
            return False

    def show_menu(self):
        """Muestra el menú principal"""
        self.show_banner()
        while True:
            print(f"\n{Fore.CYAN}=== Consola SQL Server ==={Style.RESET_ALL}")
            print(f"{Fore.YELLOW}1.{Style.RESET_ALL} Conectar a SQL Server")
            print(f"{Fore.YELLOW}2.{Style.RESET_ALL} Listar scripts disponibles")
            print(f"{Fore.YELLOW}3.{Style.RESET_ALL} Ejecutar script")
            print(f"{Fore.YELLOW}4.{Style.RESET_ALL} Salir")

            choice = input(f"\n{Fore.GREEN}Seleccione una opción: {Style.RESET_ALL}")

            if choice == '1':
                if self.connect_to_sql_server():
                    self.show_script_menu()
            elif choice == '2':
                self.list_scripts()
            elif choice == '3':
                if self.connection:
                    self.show_script_menu()
                else:
                    print(f"\n{Fore.RED}✗ Primero debe conectarse a SQL Server{Style.RESET_ALL}")
            elif choice == '4':
                if self.connection:
                    self.connection.close()
                print(f"\n{Fore.GREEN}¡Hasta pronto!{Style.RESET_ALL}")
                break
            else:
                print(f"\n{Fore.RED}✗ Opción no válida{Style.RESET_ALL}")

    def show_script_menu(self):
        """Muestra el menú de scripts"""
        while True:
            print(f"\n{Fore.CYAN}=== Scripts Disponibles ==={Style.RESET_ALL}")
            for i, script in enumerate(self.available_scripts.keys(), 1):
                print(f"{Fore.YELLOW}{i}.{Style.RESET_ALL} {script}")
            print(f"{Fore.YELLOW}{len(self.available_scripts) + 1}.{Style.RESET_ALL} Volver al menú principal")

            choice = input(f"\n{Fore.GREEN}Seleccione un script para ejecutar: {Style.RESET_ALL}")

            try:
                choice = int(choice)
                if 1 <= choice <= len(self.available_scripts):
                    script_name = list(self.available_scripts.keys())[choice - 1]
                    script_path = self.available_scripts[script_name]
                    
                    print(f"\n{Fore.CYAN}Ejecutando {script_name}...{Style.RESET_ALL}")
                    start_time = time.time()
                    
                    if self.execute_script(script_path):
                        execution_time = time.time() - start_time
                        print(f"\n{Fore.GREEN}✓ Script ejecutado en {execution_time:.2f} segundos{Style.RESET_ALL}")
                    
                    input(f"\n{Fore.YELLOW}Presione Enter para continuar...{Style.RESET_ALL}")
                elif choice == len(self.available_scripts) + 1:
                    break
                else:
                    print(f"\n{Fore.RED}✗ Opción no válida{Style.RESET_ALL}")
            except ValueError:
                print(f"\n{Fore.RED}✗ Por favor ingrese un número válido{Style.RESET_ALL}")

    def list_scripts(self):
        """Lista los scripts disponibles"""
        print(f"\n{Fore.CYAN}=== Scripts Disponibles ==={Style.RESET_ALL}")
        if not self.available_scripts:
            print(f"{Fore.YELLOW}No hay scripts disponibles.{Style.RESET_ALL}")
        else:
            for script in self.available_scripts:
                print(f"{Fore.GREEN}- {script}{Style.RESET_ALL}")
        input(f"\n{Fore.YELLOW}Presione Enter para continuar...{Style.RESET_ALL}")

def main():
    console = SQLConsole()
    console.show_menu()

if __name__ == "__main__":
    main() 