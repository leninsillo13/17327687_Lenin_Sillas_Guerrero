# Evidencia 01 — Configuración de registro por defecto

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 1 — Revisar la configuración de registro por defecto
**Fecha:** 2026-11-07
**Servidor:** PostgreSQL 18.6 en Windows (instalador de EDB), `C:/Program Files/PostgreSQL/18/data`

## Comando ejecutado

```sql
SELECT name, setting, source
FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
               'log_connections', 'log_disconnections', 'log_line_prefix',
               'log_statement', 'log_min_error_statement', 'log_timezone')
ORDER BY name;
```

## Resultado obtenido

```
          name           |               setting                |       source
-------------------------+--------------------------------------+--------------------
 log_connections         | receipt,authentication,authorization | configuration file
 log_destination         | stderr                               | configuration file
 log_directory           | log                                  | default
 log_disconnections      | on                                   | configuration file
 log_filename            | postgresql-%Y-%m-%d_%H%M%S.log       | default
 log_line_prefix         | %t                                   | configuration file
 log_min_error_statement | error                                | default
 log_statement           | none                                 | default
 log_timezone            | America/Mexico_City                  | configuration file
 logging_collector       | on                                   | configuration file
(10 filas)
```

**Diferencia con la guía:** esta instalación no trae los valores por defecto de la guía. El instalador/`postgresql.conf` ya activa el colector, las conexiones, las desconexiones y la zona horaria local. Lo que sí coincide con la guía es `log_statement = none` y un prefijo mínimo (`%t`). Además, `log_connections` es una lista de eventos (`receipt,authentication,authorization`) porque en PostgreSQL 18 dejó de ser un simple on/off.

## Respuestas

1. **Con esta configuración, ¿se registra quién se conecta?**
   Parcialmente, sí. `log_connections` ya registra los eventos `receipt`, `authentication` y `authorization`, así que quedan líneas como `conexión recibida: host=127.0.0.1`, `conexión autenticada: identidad=«…»` y `conexión autorizada: usuario=… base_de_datos=… nombre_de_aplicación=…`. El usuario y el host aparecen en el *texto del mensaje*, no en el prefijo, y solo para los eventos de conexión.

2. **¿Se registran las sentencias UPDATE?**
   No. `log_statement = none` (origen `default`): ninguna sentencia SQL se registra, solo errores.

3. **¿La línea de bitácora incluye el usuario o la dirección IP del cliente?**
   No en el prefijo. `log_line_prefix = %t` solo antepone la fecha y hora (sin milisegundos), sin PID, usuario, base, aplicación ni cliente. Cualquier línea que no sea de conexión (un error, por ejemplo) diría qué pasó pero no quién ni desde dónde.

4. **¿En qué zona horaria se registran los eventos? ¿Por qué importa al reconstruir una cronología?**
   En `America/Mexico_City` (se imprime como `CST`, UTC−6). Importa porque una cronología mezcla fuentes: la tabla de auditoría guarda `TIMESTAMPTZ` (se ve con `-06`), otros sistemas pueden registrar en UTC, y el `%t` no incluye milisegundos. Si no se sabe la zona de cada fuente, los eventos se ordenan mal o se desfasan horas.

5. **Con `logging_collector = off`, ¿quién decide dónde termina la bitácora: PostgreSQL o el mecanismo con que se desplegó el servidor?**
   El mecanismo de despliegue (script de arranque, servicio, contenedor…), porque PostgreSQL solo escribe en `stderr`. En este servidor el colector ya estaba en `on` (origen `configuration file`), por lo que es PostgreSQL quien decide: escribe en `log/` dentro del directorio de datos.

## Interpretación

Con esta configuración **no podría responderse a Dirección quién cambió el RFC**: se sabría que alguien se conectó (hora y nombre de rol), pero el `UPDATE` no se registra (`log_statement = none`) y el prefijo no identifica usuario, aplicación ni IP en las demás líneas. Que el colector ya estuviera activo resuelve la conservación del registro, pero no su contenido.
