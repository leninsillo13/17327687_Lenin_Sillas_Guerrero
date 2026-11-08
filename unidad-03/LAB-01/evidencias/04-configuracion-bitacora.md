# Evidencia 04 — Configuración de la bitácora

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 4 — Configurar la bitácora
**Fecha:** 2026-11-07

## Comandos ejecutados

Ver `sql/02-configuracion-bitacora.sql`.

```sql
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();   -- devolvió t
```

## Resultado obtenido

Consulta de verificación posterior a la recarga:

```
        name        |                 setting                 |       source       |                        sourcefile
--------------------+-----------------------------------------+--------------------+----------------------------------------------------------
 log_connections    | on                                      | configuration file | C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf
 log_disconnections | on                                      | configuration file | C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf
 log_line_prefix    | %m [%p] user=%u db=%d app=%a client=%h  | configuration file | C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf
 log_statement      | ddl                                     | configuration file | C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf
```

Primeras líneas con el prefijo nuevo (exportadas, líneas 302–305): a las 21:33:52.953 aparece el formato `%m [%p] user=… db=… app=… client=…`. Las líneas anteriores tienen el prefijo antiguo (`%t`), sin PID ni usuario.

```
302: 2026-11-07 21:33:52.953 CST [7932] user=[desconocido] db=[desconocido] app=[desconocido] client=127.0.0.1 LOG:  conexión recibida: host=127.0.0.1 port=50458
303: 2026-11-07 21:33:52.979 CST [7932] user=postgres db=comercial app=[desconocido] client=127.0.0.1 LOG:  conexión autenticada: identidad=«postgres» método=scram-sha-256 (…:147)
304: 2026-11-07 21:33:52.979 CST [7932] user=postgres db=comercial app=[desconocido] client=127.0.0.1 LOG:  conexión autorizada: usuario=postgres base_de_datos=comercial nombre_de_aplicación=psql SSL habilitado (…)
305: 2026-11-07 21:33:53.002 CST [7932] user=postgres db=comercial app=psql client=127.0.0.1 LOG:  disconnection: session time: 0:00:00.074 user=postgres database=comercial host=127.0.0.1 port=50458
```

## Hallazgo: no aparece el mensaje `parameter … changed to …`

La guía muestra que, al recargar, el proceso principal registra una línea por cada parámetro cambiado. **En este servidor esa línea no aparece**: no hay ningún mensaje de cambio de parámetro en el archivo exportado (búsquedas de `parámetro`, `cambi`, `changed` y `recarg` sin resultados, conteo = 0). Los valores sí cambiaron (consulta de `pg_settings` con `sourcefile = postgresql.auto.conf` y líneas con el prefijo nuevo), de modo que la configuración se aplicó. No determiné la causa. Mientras no se aclare, el cambio de configuración queda demostrado por: (a) `pg_settings`/`sourcefile`, (b) el prefijo nuevo que aparece desde las 21:33:52, y (c) la sentencia `ALTER SYSTEM SET log_statement = 'mod'` (línea 377), que sí quedó registrada. Las cuatro sentencias `ALTER SYSTEM` iniciales **no** quedaron registradas porque `log_statement` valía `none` cuando se ejecutaron.

## Respuestas

1. **¿Por qué el proceso que registra el cambio es el principal y no tu sesión?**
   Porque la configuración es del servidor, no de la sesión: `pg_reload_conf()` solo envía una señal al proceso principal (postmaster), que relee los archivos y avisa a los demás procesos. Por eso, cuando existe, esa línea sale con el PID del proceso principal, no con el de la sesión del administrador.

2. **¿Qué pasaría si alguien ejecutara `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?**
   Sí, siempre que `log_statement` fuera `ddl`, `mod` o `all` en ese momento: la propia sentencia se registra antes de surtir efecto (como ocurrió con la línea 377 al pasar a `mod`), con usuario, aplicación y cliente. Después de la recarga ya no se registra nada más. No quedaría rastro si quien lo hace edita el archivo a mano o controla el servidor, y en este servidor tampoco hay mensaje de cambio de parámetro.

3. **¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?**
   Porque lo gestiona `ALTER SYSTEM`: lo reescribe completo (se perderían ediciones manuales), valida el nombre y el valor del parámetro, y deja registro de la sentencia. Un error de sintaxis a mano puede impedir que el servidor lea la configuración, y el cambio no quedaría auditado.

## Interpretación

La bitácora ahora identifica la sesión (PID), el usuario, la base, la aplicación y el cliente en cada línea, y registra DDL. Esto responde «quién, desde dónde y con qué aplicación» para eventos futuros, aunque la bitácora de arranque conserva líneas con el prefijo anterior que no permiten saberlo.
