# Evidencia 02 — Colector de bitácora y vista `dba.bitacora`

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 2 — Que el servidor administre su propia bitácora
**Fecha:** 2026-11-07

## Comandos ejecutados

Ver `sql/01-colector-y-vista.sql`.

## Resultados obtenidos

Estado de `logging_collector` antes del cambio:

```
logging_collector ANTES del cambio: on
```

`pending_restart` antes de reiniciar: **No aplica: ya estaba en `on`**, no se reinició el servicio.

Comprobación del colector y archivo vigente:

```
       name        | setting |       source
-------------------+---------+--------------------
 logging_collector | on      | configuration file

          pg_current_logfile
--------------------------------------
 log/postgresql-2026-11-07_211832.log
```

Archivos del directorio de bitácoras (`pg_ls_logdir()`):

```
               name               | size  |      modification
----------------------------------+-------+------------------------
 postgresql-2026-10-17_225408.log |  7221 | 2026-10-17 23:59:14-06
 postgresql-2026-10-18_000000.log | 18011 | 2026-10-24 23:33:44-06
 postgresql-2026-10-19_000000.log |  2729 | 2026-10-25 00:33:59-06
 postgresql-2026-10-25_003359.log | 18151 | 2026-11-07 21:18:32-06
 postgresql-2026-11-07_211832.log | 32695 | 2026-11-07 21:33:46-06
```

### Problema encontrado: la vista de la guía falla en este servidor

La vista de la guía (`pg_read_file(...)`) se creó, pero **al consultarla** devolvió:

```
ERROR:  secuencia de bytes no válida para codificación «UTF8»: 0xf3 0x6e 0x20 0x72
```

`pg_read_file` convierte el contenido a la codificación de la base (UTF-8) y el archivo de bitácora contiene bytes que no son UTF-8 válido (`0xf3` es `ó` en Latin-1, en «conexión re…»). Es consecuencia de que los mensajes del servidor están en español y de que el archivo se genera en Windows. Además, el archivo tiene finales de línea `\r\n`.

Primer intento de arreglo: `CREATE OR REPLACE VIEW` falló (`no se puede cambiar el ordenamiento de la columna «linea»…`), por lo que se usó `DROP VIEW` + `CREATE VIEW`:

```sql
DROP VIEW IF EXISTS dba.bitacora;
CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(
       replace(convert_from(pg_read_binary_file(pg_current_logfile()), 'LATIN1'), E'\r', ''),
       E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';
```

```
 lineas_en_la_bitacora
-----------------------
                   659
```

Con esto la vista funciona. Efecto secundario: algunas líneas (las escritas en UTF-8, como `desconexión`) se ven con caracteres extraños (`desconexiÃ³n`). Es solo de presentación: no se pierde información y los filtros que uso evitan depender de las letras con acento (`conexi.n`, `autentificaci.n`).

Los propios intentos fallidos y la recreación de la vista quedaron en la bitácora (líneas 294, 309, 604 y siguientes del archivo exportado), lo cual es un buen ejemplo de que consultar la bitácora también deja rastro.

## Respuestas

1. **¿Por qué `logging_collector` requiere reinicio y `log_statement` solo recarga?**
   El colector es un proceso auxiliar que el proceso principal debe lanzar al arrancar y cuya tubería hereda todo proceso hijo para escribir su `stderr`; no puede añadirse a procesos ya creados, así que hay que reiniciar. `log_statement` solo es un valor que cada sesión consulta, por lo que basta con que el servidor vuelva a leer la configuración (`pg_reload_conf()`) sin cortar sesiones.

2. **¿Qué ventaja tiene que la bitácora se lea con SQL y no con una herramienta del sistema operativo o del contenedor? ¿Qué riesgo introduce?**
   Ventajas: funciona igual en cualquier plataforma, no exige acceso al sistema operativo, y permite filtrar con `LIKE`, expresiones regulares, `GROUP BY` y cruzar con la tabla de auditoría. Riesgos: requiere un rol con permiso de leer archivos del servidor (superusuario o `pg_read_server_files`), que puede leer *cualquier* archivo que vea el servicio; la bitácora puede contener secretos y datos personales; y, como vimos, tiene problemas de codificación y solo ve el archivo vigente.

3. **¿Quién debería poder consultar `dba.bitacora`?**
   Solo el administrador y, idealmente, un rol de auditoría distinto de quien opera la base. Por eso el esquema `dba` se creó con `REVOKE ALL … FROM PUBLIC`.

## Interpretación

El servidor ya administraba su propia bitácora: queda en `log/` dentro del directorio de datos y la controla PostgreSQL, no el servicio de Windows. La vista `dba.bitacora` permite leerla con SQL, pero **solo ve el archivo vigente** (`postgresql-2026-11-07_211832.log`): los cuatro archivos anteriores existen (`pg_ls_logdir()`) pero no entran en la vista, por lo que hay que exportarla y conservarla (Actividad 16).
