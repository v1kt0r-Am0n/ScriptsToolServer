# ScriptsToolServer

## Descripción
ScriptsToolServer es una colección de scripts SQL Server diseñados para facilitar la administración, monitoreo y mantenimiento de bases de datos. Estos scripts proporcionan funcionalidades avanzadas para la gestión de bases de datos, incluyendo análisis de espacio, permisos, backups y más.

## Características Principales
- 🛠️ **Herramientas de Administración**: Scripts para gestión de bases de datos
- 📊 **Monitoreo**: Análisis de espacio y rendimiento
- 🔒 **Seguridad**: Gestión de permisos y usuarios
- 📦 **Mantenimiento**: Scripts de backup y optimización
- 📝 **Documentación**: Generación de diccionarios de datos

## Scripts Disponibles

### 1. DiccionarioDeDatosDictionary.sql
Genera documentación detallada de la estructura de la base de datos.
- Documentación HTML completa
- Información de tablas, columnas y relaciones
- Compatibilidad con SQL Server 2000/2005
- Validaciones de seguridad

### 2. DiskUsegeTopTablesInfo.sql
Analiza el uso de espacio en las tablas.
- Top de tablas por tamaño
- Análisis de espacio usado/libre
- Filtros configurables
- Información detallada de índices

### 3. FueraDeLinieaDB.sql
Gestiona el estado de las bases de datos.
- Poner bases de datos fuera de línea
- Validaciones de seguridad
- Sistema de logging
- Manejo de errores robusto

### 4. GenerarScriptAUTO_SHRINK.sql
Genera scripts para optimización de espacio.
- Configuración de AUTO_SHRINK
- Validaciones de estado
- Manejo de errores
- Logging de operaciones

### 5. Generator_ATTACH_db.sql
Gestiona la operación ATTACH de bases de datos.
- Validación de archivos
- Sistema de logging
- Manejo de errores
- Verificaciones de seguridad

### 6. listar usuarios y permisos.sql
Reporte detallado de usuarios y permisos.
- Permisos a nivel de servidor
- Permisos a nivel de base de datos
- Filtros configurables
- Sistema de logging

### 7. listarBasesUnaInstancia.sql
Lista bases de datos en una instancia.
- Información detallada
- Filtros configurables
- Sistema de logging
- Métricas de rendimiento

## Requisitos
- SQL Server 2000 o superior
- Permisos de administrador para algunas operaciones
- Espacio suficiente para logs y backups

## Instalación
1. Clonar el repositorio
2. Ejecutar los scripts en la instancia de SQL Server
3. Configurar los parámetros según necesidades

## Uso
Cada script incluye:
- Documentación detallada
- Parámetros configurables
- Instrucciones de uso
- Consideraciones de seguridad

## Seguridad
- Validaciones de permisos
- Manejo seguro de errores
- Protección de datos sensibles
- Logging de operaciones

## Contribuciones
Las contribuciones son bienvenidas. Por favor:
1. Fork el repositorio
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## Licencia
Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Contacto
- Autor: Victor Macias
## - Email: [tu-email@ejemplo.com]
## - GitHub: [tu-usuario-github]

## Changelog
### v1.0.0
- Versión inicial
- Scripts base implementados
- Documentación completa
- Sistema de logging
