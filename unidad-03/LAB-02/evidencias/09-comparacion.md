# Evidencia 09 — Comparación de los tres escenarios

Leyenda: **Sí** (observado), **Parcial** (se explica), **No**. Para Enterprise/Atlas: "Documentado, no practicado" cuando corresponde.

Fuentes de cada columna:
- **PostgreSQL**: lo observado en el LAB-01 (`informe.md` del LAB-01 y `evidencias/NN-*.md`; "línea N" se refiere a `evidencias/bitacora-lab01.log` del LAB-01). Configuración final: `log_statement = mod`, `log_line_prefix` completo, `log_connections`/`log_disconnections` activos y disparador de auditoría `trg_auditoria_clientes`.
- **MongoDB Community**: lo observado en este laboratorio (perfilador + bitácora de `mongod`).
- **MongoDB Enterprise/Atlas**: lo que describe REF-U3-04 y el resumen de la materia sobre la unidad ("Documentado" = descrito en el manual oficial de MongoDB, no practicado); no se practicó.

| Evento auditable | PostgreSQL (bitácora + disparador) | MongoDB Community (perfilador + bitácora) | MongoDB Enterprise/Atlas (auditoría nativa) |
|---|---|---|---|
| Acceso exitoso | **Sí**: líneas 326–329 (`app_ventas`, `app-ventas-web`, `127.0.0.1`, `scram-sha-256`, sesión de 0.048 s). Identifica el rol, no a la persona | **Sí**: `Successfully authenticated` con usuario, cliente, aplicación, hora y `ctx` (Actividades 2, 5 y 6) | Documentado, no practicado (categoría autenticación y autorización) |
| Acceso fallido | **Sí**: líneas 313 y 319–320 (`FATAL … falló para el usuario`; `DETALLE: No existe el rol «usuario_inexistente»`) | **Sí**: `Failed to authenticate` con error, `result` (18 y 11) y cliente; un intento puede dar varias líneas (Actividad 5) | Documentado, no practicado (categoría autenticación y autorización) |
| Cambio de privilegios | **Sí**: línea 349, `GRANT UPDATE ON clientes TO app_ventas` por `postgres` (`GRANT/REVOKE` entran en `log_statement = ddl`, incluido en `mod`) | **No**: 0 resultados en perfilador y bitácora (Actividad 7). Solo queda el control compensatorio de instantáneas, que detecta **qué** rol cambió pero no **quién** ni la hora exacta, y no equivale a auditoría | Documentado, no practicado (categorías de autorización y DDL; el evento concreto debe confirmarse en REF-U3-04) |
| Cambio de estructura | **Sí**: línea 350, `ALTER TABLE clientes ADD COLUMN segmento`, atribuible | **No verificado**: no se practicó en este laboratorio; no puedo afirmarlo ni negarlo con evidencia propia | Documentado, no practicado (categoría cambios de esquema, DDL) |
| Modificación de datos | **Sí**: línea 382, `UPDATE … telefono = '6679990000' WHERE id = 3` por `app_ventas`, `app-ventas-web`, `127.0.0.1` | **Sí**: `update` y `remove` con usuario, cliente, aplicación, hora, filtro y valor nuevo (Actividades 3 y 4) | Documentado, no practicado (CRUD, requiere `auditAuthorizationSuccess: true`) |
| Valor anterior del dato | **Sí, con disparador** (`auditoria.cambios_clientes`, `JSONB` antes/después): RFC `GAMA780912XYZ → GAMA780912ZZZ`, evento 1 (`evidencias/11`). **No** si el administrador desactiva el disparador ni para cambios previos a configurarlo | **No**: el perfilador guarda el valor nuevo, no el anterior (Actividad 3) | No lo describe el manual de MongoDB (REF-U3-04); no practicado |
| Lectura de datos sensibles | **No**: `soporte_ana` leyó nombre, RFC y teléfono sin dejar rastro (`evidencias/14`); `mod` no registra `SELECT` | **Parcial**: el nivel 2 registró el `find` (filtro y `nreturned`) pero no qué datos se devolvieron; con el filtro de modificaciones no se registra (Actividad 4) | Documentado, no practicado (CRUD, requiere `auditAuthorizationSuccess: true`) |
| Cambio de configuración del registro | **Parcial**: línea 377, `ALTER SYSTEM SET log_statement = 'mod'` por `postgres` queda atribuido, pero **no apareció** el mensaje de cambio de parámetro al recargar (`evidencias/04`) | **Sí, con correlación**: `Profiler settings changed` con `from`/`to`; el autor (`admin`) se obtiene cruzando `ctx` con `Successfully authenticated` (Actividad 6) | Documentado, no practicado |

## Lectura de la comparación

- **Lo que PostgreSQL da y Community no:** autor y hora de los cambios de privilegios y de estructura (por `log_statement = ddl/mod`) y valor anterior del dato (por el disparador). Community no tiene equivalente para esos tres eventos.
- **Lo que ambos comparten:** accesos exitosos y fallidos, y modificaciones de datos con quién, cuándo y desde dónde. En ambos el rol o la cuenta es compartida, así que se identifica la cuenta y no la persona.
- **Lo que ninguno cubre bien:** las lecturas de datos sensibles. PostgreSQL con `mod` no las registra (se necesitaría `log_statement = 'all'` o pgaudit); Community solo las registra con el nivel 2, con el costo de rendimiento y de guardar los filtros en claro.
- **Límite común:** quien controla por completo el servidor puede desactivar el mecanismo (el administrador desactivó el disparador en el LAB-01; en MongoDB se puede cambiar el nivel del perfilador). Solo queda rastro en la bitácora local y se necesita custodia externa.
- **Enterprise/Atlas:** según REF-U3-04 la auditoría nativa cubriría autenticación y autorización, DDL y CRUD. No se practicó, por lo que no se afirma el alcance exacto por evento.
