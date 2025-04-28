import os
import pyodbc
import time
from datetime import datetime
import getpass

class SQLConsole:
    def __init__(self):
        self.connection = None
        self.scripts_dir = "scripts"
        self.ensure_scripts_directory()
        self.available_scripts = self.load_scripts()

    def ensure_scripts_directory(self):
        """Asegura que el directorio de scripts existe"""
        if not os.path.exists(self.scripts_dir):
            os.makedirs(self.scripts_dir)
            print(f"Directorio {self.scripts_dir} creado.")

    def load_scripts(self):
        """Carga los scripts SQL disponibles"""
        scripts = {}
        for file in os.listdir(self.scripts_dir):
            if file.endswith('.sql'):
                scripts[file] = os.path.join(self.scripts_dir, file)
        return scripts

    def connect_to_sql_server(self):
        """Establece conexión con SQL Server"""
        print("\n=== Configuración de Conexión ===")
        server = input("Servidor: ")
        database = input("Base de datos: ")
        username = input("Usuario: ")
        password = getpass.getpass("Contraseña: ")

        try:
            connection_string = (
                f"DRIVER={{SQL Server}};"
                f"SERVER={server};"
                f"DATABASE={database};"
                f"UID={username};"
                f"PWD={password}"
            )
            self.connection = pyodbc.connect(connection_string)
            print("\n✓ Conexión exitosa!")
            return True
        except Exception as e:
            print(f"\n✗ Error de conexión: {str(e)}")
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
            print("\nResultados:")
            print("-" * 80)
            for row in cursor.fetchall():
                print(dict(zip(columns, row)))
            print("-" * 80)

            cursor.close()
            return True
        except Exception as e:
            print(f"\n✗ Error al ejecutar script: {str(e)}")
            return False

    def show_menu(self):
        """Muestra el menú principal"""
        while True:
            print("\n=== Consola SQL Server ===")
            print("1. Conectar a SQL Server")
            print("2. Listar scripts disponibles")
            print("3. Ejecutar script")
            print("4. Salir")

            choice = input("\nSeleccione una opción: ")

            if choice == '1':
                if self.connect_to_sql_server():
                    self.show_script_menu()
            elif choice == '2':
                self.list_scripts()
            elif choice == '3':
                if self.connection:
                    self.show_script_menu()
                else:
                    print("\n✗ Primero debe conectarse a SQL Server")
            elif choice == '4':
                if self.connection:
                    self.connection.close()
                print("\n¡Hasta pronto!")
                break
            else:
                print("\n✗ Opción no válida")

    def show_script_menu(self):
        """Muestra el menú de scripts"""
        while True:
            print("\n=== Scripts Disponibles ===")
            for i, script in enumerate(self.available_scripts.keys(), 1):
                print(f"{i}. {script}")
            print(f"{len(self.available_scripts) + 1}. Volver al menú principal")

            choice = input("\nSeleccione un script para ejecutar: ")

            try:
                choice = int(choice)
                if 1 <= choice <= len(self.available_scripts):
                    script_name = list(self.available_scripts.keys())[choice - 1]
                    script_path = self.available_scripts[script_name]
                    
                    print(f"\nEjecutando {script_name}...")
                    start_time = time.time()
                    
                    if self.execute_script(script_path):
                        execution_time = time.time() - start_time
                        print(f"\n✓ Script ejecutado en {execution_time:.2f} segundos")
                    
                    input("\nPresione Enter para continuar...")
                elif choice == len(self.available_scripts) + 1:
                    break
                else:
                    print("\n✗ Opción no válida")
            except ValueError:
                print("\n✗ Por favor ingrese un número válido")

    def list_scripts(self):
        """Lista los scripts disponibles"""
        print("\n=== Scripts Disponibles ===")
        if not self.available_scripts:
            print("No hay scripts disponibles.")
        else:
            for script in self.available_scripts:
                print(f"- {script}")
        input("\nPresione Enter para continuar...")

def main():
    console = SQLConsole()
    console.show_menu()

if __name__ == "__main__":
    main() 