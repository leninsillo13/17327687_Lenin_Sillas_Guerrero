# LAB-04 — Hardening y configuración segura de PostgreSQL

## Objetivo

Identificar la superficie de ataque de un servidor PostgreSQL, aplicar medidas de hardening basadas en el principio de mínimo privilegio y verificar que cada cambio redujo la exposición sin interrumpir el servicio.

## Entorno

| Elemento | Valor |
|---|---|
| Motor | PostgreSQL 18.6 (x86_64-windows, msvc-19.44) |
| Sistema operativo | Windows (servicio `postgresql-x64-18`, cuenta `NT AUTHORITY\NetworkService`) |
| Cliente | pgAdmin 4 y psql |
| Directorio de datos | `C:/Program Files/PostgreSQL/18/data` |
| Bases de datos | `postgres`, `laboratorios` |

## Superficie de ataque inicial

| Elemento | Estado inicial | ¿Es necesario? | Riesgo |
|---|---|---|---|
| Puerto | 5432 (por defecto) | Sí | Bajo/Medio |
| Interfaces de escucha | `*` (`0.0.0.0` y `[::]`) | No, solo se usa localhost | **Alto** |
| Conexiones remotas | Ninguna activa (solo `::1`) | No | Medio |
| Usuarios administrativos | `postgres` usado como cuenta de trabajo | No debería | **Alto** |
| TLS | `ssl = off`, sin certificado | Sí | Medio/Alto |
| Autenticación | `scram-sha-256` | Sí | Bajo |
| Registro de conexiones | `log_connections` vacío, `log_disconnections = off` | Sí | Medio |

Evidencia: `evidencias/superficie-ataque.png`, `evidencias/listen-addresses.png`

## Hallazgos

1. **Escucha en todas las interfaces** (`listen_addresses = '*'`), confirmado con `netstat`, aunque todos los clientes se conectaban desde `::1`.
2. **Todo el trabajo se hacía con `postgres` (SUPERUSER)**, el único rol con `LOGIN`. No existían cuentas de aplicación.
3. **TLS apagado** y sin `server.crt` ni `server.key`.
4. **Sin registro de conexiones ni desconexiones.**
5. **Sin límites de sesión** (`statement_timeout = 0`, `idle_in_transaction_session_timeout = 0`).
6. `pg_hba.conf` ya limitaba el origen a localhost y usaba `scram-sha-256`, pero con `all`/`all` y reglas de `replication` sin uso.
7. `pgcrypto` instalada sin objetos que la usaran.
8. Firewall activo en los tres perfiles y sin regla de entrada para el puerto 5432.
9. Permisos del sistema operativo adecuados (sin acceso para `Users` ni `Everyone`).
10. `analista` tiene `SELECT` directo sobre `analitica.clientes` (pendiente de revisar).

## Cambios realizados

Detalle técnico (valor anterior, nuevo, reversión) en `configuracion/cambios.md`.

| # | Cambio | Antes | Después |
|---|---|---|---|
| 1 | Cuentas separadas | Solo `postgres` con `LOGIN` | `dba_lab`, `app_lab` y `consulta_lab` |
| 2 | `pg_hba.conf` | 6 reglas `all`/`all` | 11 reglas por base + usuario + origen; sin `replication` |
| 3 | `listen_addresses` | `*` | `localhost` |
| 4 | Timeouts | `0` | `idle_in_transaction_session_timeout = 5min`; `statement_timeout = 30s` para `app_lab` |
| 5 | TLS | `off` | `on` con certificado autofirmado, mínimo TLS 1.2 |
| 6 | Extensiones | `plpgsql`, `pgcrypto` | Solo `plpgsql` |
| 7 | Registro de conexiones | Desactivado | `receipt,authentication,authorization` y desconexiones |

## Justificación de los cambios

- **Cuentas separadas:** una aplicación comprometida no debe heredar control total del servidor (mínimo privilegio).
- **`pg_hba.conf` específico:** restringe base de datos, usuario, origen y método, no solo el origen.
- **`listen_addresses = 'localhost'`:** elimina la superficie de red en lugar de solo restringirla. Fue el cambio de mayor reducción de exposición.
- **Timeouts:** evitan transacciones abandonadas que retienen bloqueos y consultas sin límite.
- **TLS:** cifra credenciales y datos en tránsito.
- **Eliminar `pgcrypto`:** habilitar solo la funcionalidad necesaria.
- **Logs de conexión:** sin ellos no hay monitoreo ni forma de investigar un incidente.

## Verificación

| Verificación | Resultado |
|---|---|
| `SHOW listen_addresses` | `localhost` |
| `netstat` | Solo `127.0.0.1:5432` y `[::1]:5432` |
| `pg_hba_file_rules` | 11 reglas, sin errores |
| `consulta_lab` → base `postgres` | Rechazado |
| `consulta_lab` → `CREATE TABLE` | `permission denied for schema public` |
| `pg_stat_ssl` | `ssl = true`, TLSv1.3, `TLS_AES_256_GCM_SHA384` |
| `SHOW idle_in_transaction_session_timeout` | `5min` |
| Extensiones | Solo `plpgsql` |
| `log_connections` / `log_disconnections` | `receipt,authentication,authorization` / `on` |

Evidencias: `evidencias/pg-hba.png`, `roles.png`, `tls.png`, `verificacion.png`. Scripts en `sql/`.

## Checklist de hardening

| # | Control | Verificado |
|---|---|---|
| 1 | Puerto documentado | Sí |
| 2 | Interfaces de escucha justificadas | Sí |
| 3 | `pg_hba.conf` revisado | Sí |
| 4 | Redes autorizadas restringidas | Sí |
| 5 | Autenticación segura (`scram-sha-256`) | Sí |
| 6 | Superusuarios identificados | Sí |
| 7 | Cuentas de aplicación separadas | Sí |
| 8 | Privilegios mínimos | Sí |
| 9 | Extensiones revisadas | Sí |
| 10 | TLS verificado | Sí |
| 11 | Configuración protegida | Sí |
| 12 | Directorio de datos protegido | Sí |
| 13 | Firewall documentado | Sí |
| 14 | Actualizaciones documentadas | Sí |
| 15 | Configuración registrada | Sí |
| 16 | Límites de sesión | Sí |
| 17 | Registro de conexiones | Sí |
| 18 | Replicación no usada deshabilitada | Sí |
| 19 | Obligar TLS (`hostssl`) | No (mejora futura) |
| 20 | `postgres` sin uso diario | Parcial |

Detalle de evidencias en `informe.md`.

## Conclusiones

- Conocer la superficie de ataque antes de cambiar nada permitió priorizar: lo más grave no era `pg_hba.conf` (ya restrictivo), sino la escucha en todas las interfaces y el uso de un superusuario como cuenta de trabajo.
- Ningún control basta por sí solo. La seguridad es la suma de red, autenticación, autorización, configuración, sistema operativo y monitoreo.
- **Limitaciones:** el certificado es autofirmado (no permite `verify-full`); TLS está disponible pero no es obligatorio (las reglas son `host`, no `hostssl`); pgAdmin aún conecta con `postgres`.
- **Mejoras futuras:** reglas `hostssl`, certificado de una CA, migrar pgAdmin a `dba_lab`, revisar el `SELECT` directo de `analista` sobre `analitica.clientes` y revisión trimestral de los controles.

Informe completo: `informe.md`. Baseline: `configuracion/baseline.md`.