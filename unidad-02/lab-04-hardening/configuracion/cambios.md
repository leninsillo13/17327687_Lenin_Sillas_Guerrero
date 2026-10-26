# Registro de cambios: LAB-04

Fecha de inicio: 2026-10-25
Servidor: PostgreSQL 18.6 en Windows (`C:/Program Files/PostgreSQL/18/data`)

## Cambio 0: Respaldo de configuración

| Campo | Detalle |
|---|---|
| Archivos | `postgresql.conf`, `pg_hba.conf` |
| Acción | Copia a `postgresql.conf.bak` y `pg_hba.conf.bak` en el mismo directorio |
| Motivo | Permitir revertir si un cambio impide el acceso |
| Reversión | `Copy-Item <archivo>.bak <archivo> -Force` |

## Cambio 1: Creación de cuentas separadas

| Campo | Detalle |
|---|---|
| Valor anterior | Solo `postgres` (SUPERUSER) podía iniciar sesión; todo se hacía con esa cuenta |
| Valor nuevo | Roles `dba_lab` (administrativo, sin SUPERUSER), `app_lab` (miembro de `soporte`) y `consulta_lab` (miembro de `analista`) |
| Motivo | Mínimo privilegio y separación de funciones |
| Reversión | `DROP ROLE dba_lab, app_lab, consulta_lab;` |

## Cambio 2: Reglas de `pg_hba.conf`

| Campo | Detalle |
|---|---|
| Valor anterior | `local/host all all` para `127.0.0.1/32` y `::1/128`, más 3 reglas de `replication` |
| Valor nuevo | Reglas por base de datos + usuario + origen para `postgres`, `dba_lab`, `app_lab` y `consulta_lab`; reglas de `replication` eliminadas |
| Motivo | Restringir usuario y base además del origen; quitar replicación no usada |
| Aplicación | `SELECT pg_reload_conf();` (sin reinicio) |
| Reversión | Restaurar `pg_hba.conf.bak` y recargar |
| Estado | Sintaxis verificada con `pg_hba_file_rules` (sin errores). Pruebas de acceso por rol en curso. |

## Cambio 3: `listen_addresses`

| Campo | Detalle |
|---|---|
| Valor anterior | `*` |
| Valor nuevo | `localhost` |
| Motivo | Solo se usan clientes locales |
| Aplicación | Editar `postgresql.conf` y `Restart-Service postgresql-x64-18` |
| Reversión | Restaurar `postgresql.conf.bak` y reiniciar |
| Estado | Aplicado y verificado: `SHOW listen_addresses` = `localhost`; `netstat` solo muestra `127.0.0.1:5432` y `[::1]:5432`. |

## Cambio 4: Timeouts de sesión

| Campo | Detalle |
|---|---|
| Valor anterior | `idle_in_transaction_session_timeout = 0`, `statement_timeout = 0` |
| Valor nuevo | `idle_in_transaction_session_timeout = '5min'`. `statement_timeout = '30s'` solo para `app_lab` |
| Motivo | Evitar transacciones abandonadas y consultas sin límite |
| Aplicación | `ALTER SYSTEM SET idle_in_transaction_session_timeout = '5min'; SELECT pg_reload_conf(); ALTER ROLE app_lab SET statement_timeout = '30s';` |
| Reversión | `ALTER SYSTEM RESET idle_in_transaction_session_timeout; ALTER ROLE app_lab RESET statement_timeout;` y recargar |
| Estado | Aplicado y verificado. |

## Cambio 5: TLS

| Campo | Detalle |
|---|---|
| Valor anterior | `ssl = off`, sin certificado ni clave |
| Valor nuevo | `ssl = on` con `server.crt` y `server.key` |
| Aplicación | Certificado con OpenSSL (Git for Windows). `ALTER SYSTEM SET ssl = on; SELECT pg_reload_conf();` |
| Reversión | `ALTER SYSTEM RESET ssl;` y recargar. Los archivos `server.crt` y `server.key` pueden eliminarse |
| Estado | Aplicado y verificado: `SHOW ssl` = `on`; `pg_stat_ssl` muestra TLSv1.3 con `TLS_AES_256_GCM_SHA384`. |

## Cambio 6: `pgcrypto`

| Campo | Detalle |
|---|---|
| Valor anterior | Instalada (v1.4) |
| Valor nuevo | Eliminada |
| Motivo | Sin objetos dependientes; funcionalidad innecesaria |
| Aplicación | `DROP EXTENSION pgcrypto;` |
| Reversión | `CREATE EXTENSION pgcrypto;` |
| Estado | Aplicado y verificado: `SELECT extname FROM pg_extension` devuelve solo `plpgsql`. |

## Cambio 7: Registro de conexiones

| Campo | Detalle |
|---|---|
| Valor anterior | `log_connections` vacío, `log_disconnections = off` |
| Valor nuevo | `log_connections = 'receipt,authentication,authorization'`, `log_disconnections = on` |
| Motivo | Tener rastro de quién se conecta y cuándo (monitoreo) |
| Reversión | `ALTER SYSTEM RESET log_connections; ALTER SYSTEM RESET log_disconnections;` y recargar |
| Estado | Aplicado y verificado: `SHOW log_connections` = `receipt,authentication,authorization`; `SHOW log_disconnections` = `on`. |