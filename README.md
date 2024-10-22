# SQL Server Scripts Repository

Este repositorio contiene una colección de scripts útiles para la administración, configuración y operación de bases de datos en SQL Server. Los scripts cubren tareas comunes como la gestión de usuarios, cambio de propietarios, optimización de consultas, backup y restauración, entre otros.

## Estructura del Repositorio

La estructura del repositorio es la siguiente:


### Carpetas principales

- **user-management**: Scripts relacionados con la gestión de usuarios y propietarios de bases de datos.
- **backup**: Scripts para realizar copias de seguridad completas, diferenciales y de logs de transacciones.
- **optimization**: Scripts orientados a la optimización de índices y consultas SQL.
- **maintenance**: Scripts para el mantenimiento de bases de datos, como la reconstrucción de índices y la reducción del tamaño de bases de datos.

## Requisitos

- SQL Server 2016 o superior.
- Un usuario con permisos de administrador en las bases de datos.

## Uso

1. **Cambiar el propietario de una base de datos**: Usa el script `user-management/change-db-owner.sql` para cambiar el propietario de una base de datos específica.
   ```sql
   USE [NombreDeLaBaseDeDatos];
   EXEC sp_changedbowner '[NuevoPropietario]';
# ScriptsToolServer
ScriptsToolServer
Scripts para Server v.0.0.1
Contribuir

Si deseas contribuir a este repositorio, sigue los siguientes pasos:

    Haz un fork del proyecto.
    Crea una rama nueva (git checkout -b feature/nueva-funcionalidad).
    Realiza tus cambios.
    Haz un commit de tus cambios (git commit -am 'Añadida nueva funcionalidad').
    Sube los cambios a tu rama (git push origin feature/nueva-funcionalidad).
    Crea un Pull Request.

Licencia

Este repositorio está bajo la licencia MIT. Para más detalles, consulta el archivo LICENSE.
