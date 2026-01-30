# Tests

Valida el funcionamiento del sistema de backup y restore de PostgreSQL.

## Requisitos

- Docker y Docker Compose
- Servicios corriendo (`./init.sh --start`)

## Ejecutar

```bash
./tests/run-tests.sh
```

## Qué se testea

### Entorno
- Docker daemon activo
- Contenedor PostgreSQL corriendo y saludable

### Conectividad
- Conexión directa a PostgreSQL via `docker exec`

### Backup
- Creación de base de datos temporal con datos de prueba
- Ejecución del script `backup.sh`
- Verificación de archivo `.sql.gz` generado

### Restore
- Eliminación de datos de la base de prueba
- Restauración desde el backup creado
- Verificación de integridad: cantidad de registros y valores específicos

## Limpieza

El script elimina automáticamente al finalizar:
- Base de datos `_test_db`
- Archivos de backup generados durante el test
