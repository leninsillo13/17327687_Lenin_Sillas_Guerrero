# Evidencia 15 — Cronología y respuestas a Dirección

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 17 — Reconstruir la cronología y responder a Dirección
**Fecha:** 2026-11-07

Fuentes: `bitacora-lab01.log` (SHA-256 en `bitacora-lab01.sha256`; el número de línea es el mismo que `num` en `dba.bitacora`) y `auditoria.cambios_clientes` (`id_evento`). Horas en `America/Mexico_City` (CST, UTC−6). La columna «Cliente» es el cliente de la tabla `clientes` afectado.

## Cronología

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-07 21:18:33 | (sin dato: prefijo `%t`) | — | Configuración | Registro más antiguo del archivo vigente: «el sistema de bases de datos fue apagado en 21:18:32» (el servidor arranca el archivo de bitácora) | Sí | línea 1 |
| 2 | 21:18:33 – 21:19:25 | postgres, app_ventas, soporte_ana, usuario_inexistente (rol en el mensaje) | — | Acceso | Decenas de rechazos «no hay una línea en pg_hba.conf para 127.0.0.1…» (con y sin SSL). Corresponden a la preparación de las reglas de acceso | No | líneas 7–205 |
| 3 | 21:24:27 y 21:30:13 | postgres | — | Acceso | Dos intentos (cada uno con 2 líneas `FATAL`) con contraseña incorrecta | No | líneas 215–230 |
| 4 | 21:33:46 | app_ventas (app-ventas-web) | 3 | Datos | **Hueco:** una sesión de `app_ventas` (288–290, 0.050 s). No hay sentencia: `log_statement = none` y la auditoría no existía. Cambio de RFC `GHI → XXX` **sin evidencia** | — | líneas 288–290 |
| 5 | 21:33:52.953 | — | — | Configuración | El prefijo de línea cambia al formato nuevo (`user= db= app= client=`). No hay línea `parameter … changed`; los `ALTER SYSTEM` iniciales no se registraron | Sí | líneas 302–305; `pg_settings` |
| 6 | 21:33:56.224 – .427 | app_ventas ×2, usuario_inexistente ×2 | — | Acceso | 4 líneas `FATAL` de contraseña incorrecta (2 por intento); el rol inexistente queda indicado en `DETALLE` | No | 313, 316, 319–320, 323–324 |
| 7 | 21:33:56.528 | app_ventas (app-ventas-web) | — | Acceso | Conexión autenticada y autorizada (scram-sha-256, regla 149) y desconexión (0.048 s) | Sí | 327–329 |
| 8 | 21:33:59.863 – .865 | postgres | — | Privilegio | `REVOKE UPDATE … FROM soporte_ana`; `GRANT UPDATE … TO app_ventas` | Sí | 348, 349 |
| 9 | 21:33:59.867 | postgres | — | Estructura | `ALTER TABLE clientes ADD COLUMN segmento` | Sí | 350 |
| 10 | 21:34:00.091 – .103 | postgres | — | Privilegio | `CREATE ROLE rol_temporal … PASSWORD '<REDACTED>'` y `DROP ROLE rol_temporal` (el secreto quedó en la bitácora original) | Sí | 355, 356 |
| 11 | 21:34:03.431 | app_ventas (app-ventas-web) | 3 | Datos | **Hueco:** sesión de 0.051 s (365–367) sin sentencia (`ddl`). Cambio de RFC `XXX → XYZ` **sin evidencia** directa | — | 365–367 |
| 12 | 21:34:06.664 | postgres | — | Configuración | `ALTER SYSTEM SET log_statement = 'mod'` | Sí | 377 |
| 13 | 21:34:09.796 | app_ventas (app-ventas-web, 127.0.0.1) | 3 | Datos | `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` (el `SELECT` posterior del RFC no se registra) | Sí | 382 |
| 14 | 21:34:13.009 – .012 | soporte_ana (psql) | 5 | Error | `DELETE FROM clientes WHERE id = 5` → «permiso denegado a la tabla clientes» | No | 395–397 |
| 15 | 21:34:13.118 – .120 | postgres | — | Error | `DROP ROLE soporte_ana` → «otros objetos dependen de él» (privilegios sobre `clientes`) | No | 402–405 |
| 16 | 21:34:23.681 – .829 | postgres | — | Estructura | `CREATE SCHEMA auditoria`, `REVOKE … FROM PUBLIC`, `CREATE TABLE`, `CREATE FUNCTION`, `REVOKE ON FUNCTION`, `CREATE TRIGGER` | Sí | 434–436, 452, 475, 476 |
| 17 | 21:34:27.041 | app_ventas (app-ventas-web, 127.0.0.1) | 3 | Datos | `UPDATE … SET rfc = 'GAMA780912ZZZ'`; antes `XYZ`, después `ZZZ` | Sí | línea 491; id_evento 1 |
| 18 | 21:34:27.158 | app_ventas (psql) | — | Error | `SELECT * FROM auditoria.cambios_clientes` → «permiso denegado al esquema auditoria» | No | 496–497 |
| 19 | 21:34:27.477 – .482 | postgres (psql, 127.0.0.1) | 6 | Datos | `INSERT` y `DELETE` de Pedro Ruiz (RUPE950101AAA) | Sí | 510, 512; id_evento 2 y 3 |
| 20 | 21:34:27.710 – .712 | app_ventas (app-ventas-web) | — | Error | Intento de `DELETE FROM auditoria.cambios_clientes` y de `DISABLE TRIGGER` | No | 517–521 |
| 21 | 21:34:28.032 – .037 | postgres (psql) | 3 | Datos / Estructura | `DISABLE TRIGGER`, `UPDATE rfc = 'GAMA780912GHI'`, `ENABLE TRIGGER`. **El UPDATE no está en la auditoría** | Sí | 531–533 |
| 22 | 21:34:31.364 | soporte_ana | 3 | Datos (lectura) | **Hueco:** lectura de nombre, RFC y teléfono; solo quedan conexión y desconexión | — | 544–546 |
| 23 | 21:34:31.474 | postgres (psql) | 1–5 | Datos | `UPDATE clientes SET segmento = 'regular'` sin `WHERE` (1 línea; 5 filas de auditoría) | Sí | 550; id_evento 4–8 |

## Respuestas a Dirección (solo con la evidencia)

**1. ¿Quién cambió el RFC la primera vez (Actividad 3)? ¿Y en las Actividades 7, 12 y 14?**

| Cambio | ¿Hay evidencia? | Detalle |
|---|---|---|
| Actividad 3 (21:33:46, `GHI → XXX`) | **No hay evidencia** | `log_statement = none` y no existía el disparador. Solo consta una sesión de `app_ventas` en esa hora (288–290); no demuestra que haya sido quien hizo el cambio |
| Actividad 7 (21:34:03, `XXX → XYZ`) | **No hay evidencia directa** | `log_statement = ddl` no registra `UPDATE`. Solo la sesión de `app_ventas` (365–367). El valor `XYZ` consta indirectamente: es el `valores_antes` del evento 1 |
| Actividad 12 (21:34:27.041, `XYZ → ZZZ`) | **Sí** | `app_ventas`, aplicación `app-ventas-web`, `127.0.0.1`; id_evento 1 y bitácora línea 491 |
| Actividad 14 (21:34:28.034, `ZZZ → GHI`) | **Parcial** | Quién y cuándo: `postgres`, `psql`, `127.0.0.1` (línea 532), con el nuevo valor `GHI` en el texto de la sentencia. No está en la auditoría (disparador desactivado, 531–533), así que el valor anterior no se registró |

**2. ¿Quién cambió el teléfono?**
`app_ventas`, aplicación `app-ventas-web`, desde `127.0.0.1`, a las 21:34:09.796 (línea 382: `telefono = '6679990000' WHERE id = 3`). El teléfono anterior **no tiene evidencia**: el disparador aún no existía; el evento 1 muestra `6679990000` como valor ya vigente.

**3. ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?**
Sí, todos desde `127.0.0.1`: (a) 21:33:56: `app_ventas` ×2 y `usuario_inexistente` ×2 (los que se provocaron en la Actividad 5); (b) 21:24:27 y 21:30:13: `postgres` por contraseña incorrecta; (c) 21:18:33–21:19:25: rechazos por falta de regla en `pg_hba.conf` para `postgres`, `app_ventas`, `soporte_ana` y `usuario_inexistente`. Antes del primer cambio de RFC (21:33:46) hubo (b) y (c), explicados por la preparación del entorno, pero la bitácora no puede distinguir esos intentos de un ataque. Las líneas de (b) y (c) tienen el prefijo antiguo `%t`, sin cliente; el origen solo se deduce de la línea `conexión recibida: host=127.0.0.1` que las precede.

**4. ¿Qué valor tenía el RFC antes de cada cambio?**
- Antes del cambio de la Actividad 3: `GAMA780912GHI`, según el script de carga, **no** según la bitácora ni la auditoría.
- Antes del de la Actividad 7 (`XXX`): **No hay evidencia** en el servidor (solo el script de la práctica).
- Antes del de la Actividad 12: `GAMA780912XYZ` (auditoría, evento 1).
- Antes del de la Actividad 14: **No hay evidencia directa**; por la cadena de eventos se infiere `ZZZ`, pero no está registrado.

**5. ¿Quién hizo el cambio sin auditar (Actividad 14)?**
`postgres` (aplicación `psql`, `127.0.0.1`), a las 21:34:28.034, según la bitácora (531–533).

## Huecos declarados

- Cambios de RFC de las Actividades 3 y 7: sentencia no registrada, sin hora exacta del `UPDATE` (solo la ventana de la sesión).
- Lectura de datos por `soporte_ana` (21:34:31): no se registran lecturas con `mod`.
- Cambio de configuración inicial (21:33:49–52): las sentencias `ALTER SYSTEM` no se registraron y tampoco aparece el mensaje `parameter … changed`.
- Valor anterior del teléfono y del RFC antes del disparador.
- Cambio del administrador con el disparador desactivado: sin valor anterior.

## Interpretación

La bitácora y la auditoría solo prueban lo que estaba configurado cuando ocurrió el evento. Con ambos mecanismos activos se demuestra quién, cuándo, desde dónde y qué valor tenía el RFC para los cambios hechos por `app_ventas`. Los cambios anteriores a la configuración, las lecturas y los cambios del administrador con el disparador desactivado se declaran como huecos.
