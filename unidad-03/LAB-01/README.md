# LAB-01 — Bitácoras y auditoría del dato en PostgreSQL

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos
**Estudiante:** Lenin Sillas Guerrero
**Fecha de ejecución:** 2026-11-07 (horas en `America/Mexico_City`, CST, UTC−6)

## Despliegue utilizado (Anexo A)

| Elemento | Valor |
|---|---|
| Motor | PostgreSQL **18.6** (`x86_64-windows`, compilado con msvc-19.44), instalación **nativa con el instalador de EDB** |
| Versión de la guía | PostgreSQL 16 (se usó 18.6; ver diferencias) |
| Directorio de datos | `C:/Program Files/PostgreSQL/18/data` |
| `config_file` / `hba_file` | `…/data/postgresql.conf` / `…/data/pg_hba.conf` |
| Base de datos | `comercial` (tabla `clientes`, roles `app_ventas` y `soporte_ana`) |
| Cliente | `psql` en el mismo equipo; conexiones de red a `127.0.0.1` (TCP con SSL/TLS 1.3, `scram-sha-256`) |
| Sesión de administrador | `psql -U postgres -d comercial` (por TCP, no por socket) |
| Idioma de los mensajes del servidor | Español |

## Diferencias respecto a la guía (y cómo se trataron)

1. **Configuración inicial distinta.** El servidor ya tenía `logging_collector = on`, `log_connections` (receipt, authentication, authorization), `log_disconnections = on`, `log_line_prefix = %t` y `log_timezone = America/Mexico_City`. Por eso no hizo falta reiniciar (Actividad 2), y en la Actividad 3 sí aparece la conexión de `app_ventas`.
2. **`pg_hba.conf` sin `trust`.** No había reglas `host` con `trust` para `127.0.0.1`/`::1` (hay una regla `local` para `postgres` y reglas `host` con `scram-sha-256`); no fue necesario editar el archivo.
3. **Mensajes en español.** Los patrones de búsqueda de la guía (`statement:`, `connection authorized`, `ERROR:  permission…`) se adaptaron (`sentencia:`, `conexión autorizada`, `SENTENCIA:`, `DETALLE:`).
4. **Codificación del archivo de bitácora.** La vista `dba.bitacora` de la guía falla (`secuencia de bytes no válida para codificación «UTF8»`). Se recreó con `pg_read_binary_file` + `convert_from(…,'LATIN1')` y se quitaron los `\r` (detalle en `evidencias/02-colector.md`). Algunas líneas se ven con caracteres extraños (`desconexiÃ³n`); es solo presentación.
5. **No aparece el mensaje `parameter … changed to …`** al recargar la configuración (detalle en `evidencias/04-configuracion-bitacora.md`). La causa no se determinó.
6. **Sesión de administrador por TCP.** En la auditoría `ip_cliente` del administrador es `127.0.0.1` (la guía muestra vacío al usar socket), y en `pg_stat_activity` su `client_addr` también es `127.0.0.1`.
7. **Reporte de la Actividad 9:** `pg_sleep(30)` en vez de `pg_sleep(90)`.
8. **Contraseñas:** se asignaron con `ALTER ROLE … PASSWORD` desde un script con `log_statement = 'none'` en esa sesión (la guía usa `\password` de forma interactiva). No quedaron en la bitácora.
9. **Parte C (pgaudit): no se realizó** (es opcional); por eso no existe `evidencias/16-pgaudit.md`.

## Integridad de la bitácora exportada

`bitacora-lab01.log` es el archivo vigente `log/postgresql-2026-11-07_211832.log`, exportado a las 21:56 con la contraseña del rol temporal sustituida por `<REDACTED>`.

```
bac2e245354dc392da2c29bd975da679de5d6d859d9cb61276c192267a3549a9  evidencias/bitacora-lab01.log
```

Verificación (PowerShell): `Get-FileHash evidencias/bitacora-lab01.log -Algorithm SHA256`. El hash se comprobó contra el archivo entregado y coincide.

## Verificación final (sección 26)

**Parte A** — `pg_settings`:

| Parámetro | Valor | Origen |
|---|---|---|
| logging_collector | on | configuration file |
| log_connections | on | configuration file |
| log_disconnections | on | configuration file |
| log_statement | mod | configuration file |
| log_line_prefix | `%m [%p] user=%u db=%d app=%a client=%h ` | configuration file |

- [x] Acceso fallido por contraseña incorrecta y por usuario inexistente (líneas 313, 316, 319–320, 323–324)
- [x] Acceso exitoso con su desconexión (327–329)
- [x] `GRANT`, `REVOKE` y `ALTER TABLE` (348–350)
- [x] `UPDATE` registrado con usuario, IP y aplicación (382, 491)
- [x] Error de permisos con su sentencia (395–397)
- [ ] Cambio de configuración `parameter … changed to …` — **no apareció**; solo consta la sentencia `ALTER SYSTEM SET log_statement = 'mod'` (377)

**Parte B**

- [x] El esquema `auditoria` no tiene acceso para `PUBLIC` (`has_schema_privilege = f`)
- [x] Disparador habilitado (`tgenabled = O`)
- [x] La auditoría contiene UPDATE (6), INSERT (1) y DELETE (1)
- [x] El UPDATE de `app_ventas` muestra `usuario_sesion = app_ventas`
- [x] La bitácora registra la desactivación y reactivación del disparador (531, 533)

**Parte C** — no realizada.