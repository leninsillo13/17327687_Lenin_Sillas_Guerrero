# Informe — LAB-01: Bitácoras y auditoría del dato en PostgreSQL

**Estudiante:** Lenin Sillas Guerrero
**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos — Unidad III
**Fecha:** 2026-11-07
**Referencias a evidencias:** `evidencias/NN-*.md`. «Línea N» se refiere a `evidencias/bitacora-lab01.log` (SHA-256 `bac2e245…3549a9`).

## 1. Despliegue y situación inicial

El servidor es una instalación nativa de **PostgreSQL 18.6 en Windows** (instalador de EDB), con directorio de datos `C:/Program Files/PostgreSQL/18/data`, base `comercial` y roles `app_ventas` (SELECT, UPDATE) y `soporte_ana` (SELECT). Los mensajes están en español. La guía está escrita para PostgreSQL 16; las diferencias y su tratamiento están en el `README.md`.

La configuración de registro que traía el servidor (`evidencias/01`) era: colector activo, conexiones y desconexiones registradas, `log_line_prefix = %t`, `log_statement = none` y zona `America/Mexico_City`. Con ella:

- Se sabía que alguien se conectó (hora y rol en el texto del mensaje), pero ninguna sentencia SQL quedaba registrada.
- El prefijo no incluía PID, usuario, base, aplicación ni cliente, de modo que solo las líneas de conexión decían «quién».

Por eso el primer `UPDATE` del RFC (Actividad 3) no dejó rastro: solo una sesión de `app_ventas` de 0.050 s (líneas 288–290). El servidor no podía responder a Dirección quién cambió el dato, cuándo ni con qué valor anterior (`evidencias/03`). Las reglas de `pg_hba.conf` ya exigían `scram-sha-256`, así que los accesos fallidos sí eran observables.

## 2. Configuración aplicada

| Parámetro | Valor | Cómo se cambió | ¿Recarga o reinicio? | Justificación |
|---|---|---|---|---|
| `logging_collector` | `on` (ya estaba) | `postgresql.conf` | Reinicio (no hizo falta) | El propio servidor administra y conserva la bitácora, sin depender del despliegue |
| `log_connections` | `on` | `ALTER SYSTEM` | Recarga | Accesos exitosos y fallidos |
| `log_disconnections` | `on` | `ALTER SYSTEM` | Recarga | Duración y fin de cada sesión |
| `log_line_prefix` | `%m [%p] user=%u db=%d app=%a client=%h ` | `ALTER SYSTEM` | Recarga | Milisegundos, PID (agrupa la sesión), usuario, base, aplicación y cliente: sin esto una línea no dice quién ni desde dónde |
| `log_statement` | `ddl` → **`mod`** | `ALTER SYSTEM` | Recarga | `ddl` registra privilegios y estructura; `mod` añade `INSERT/UPDATE/DELETE`. No se usó `all`: registra todo, genera mucho volumen y copia datos sensibles al archivo |
| `log_min_error_statement` | `error` (defecto) | — | — | Registra la sentencia que causa cada error |

Los cambios se verificaron con `pg_settings` (origen `configuration file`, archivo `postgresql.auto.conf` y `evidencias/04`. Se creó la vista `dba.bitacora` sobre un esquema sin acceso para `PUBLIC` (`evidencias/02`), corregida para el problema de codificación del archivo.

## 3. Eventos observados

Un ejemplo interpretado de cada tipo (con `mod`, salvo indicación):

| Tipo | Ejemplo (fuente) | Interpretación |
|---|---|---|
| Acceso exitoso | Líneas 326–329: `app_ventas`, `app-ventas-web`, `127.0.0.1`, `scram-sha-256` regla 149, sesión de 0.048 s | Se demuestra quién (rol), desde dónde y cuándo; no demuestra qué persona |
| Acceso fallido | Líneas 313 y 319–320: `FATAL … falló para el usuario «app_ventas»`, `DETALLE: No existe el rol «usuario_inexistente»` | Se demuestra desde dónde se intentó entrar; el detalle del rol inexistente solo está en el servidor, no en el mensaje al cliente |
| Privilegio | Línea 349: `GRANT UPDATE ON clientes TO app_ventas` por `postgres` | Quién cambió permisos. `GRANT/REVOKE` entran en `ddl` |
| Estructura | Línea 350: `ALTER TABLE clientes ADD COLUMN segmento` | Cambio de estructura atribuible |
| Datos | Línea 382: `UPDATE … telefono = '6679990000' WHERE id = 3` por `app_ventas`, `app-ventas-web`, `127.0.0.1` | Quién, cuándo y qué se ejecutó, pero no el valor anterior |
| Error | Líneas 395–397: `soporte_ana` intenta `DELETE` → «permiso denegado a la tabla clientes» | Intento rechazado: sin daño, pero es un indicio y prueba que el control funcionó |
| Configuración | Línea 377: `ALTER SYSTEM SET log_statement = 'mod'` por `postgres` | Cambio de configuración atribuible. **No apareció** el mensaje `parameter … changed to …` de la recarga (`evidencias/04`) |

También se comprobó la diferencia entre bitácora y `pg_stat_activity` (`evidencias/09`): la vista muestra la sesión `16124` solo mientras corre el reporte; la bitácora conserva su historia (líneas 661–663 y 672, 30 s de duración).

## 4. Auditoría del dato

**Diseño.** La tabla `auditoria.cambios_clientes` (esquema sin acceso para `PUBLIC`) guarda `momento` (`TIMESTAMPTZ`), `usuario_sesion`, `usuario_efectivo`, `aplicacion`, `ip_cliente` y la fila completa antes y después en `JSONB`. Cada campo responde una pregunta de Dirección (`evidencias/10`). El `JSONB` conserva el estado completo aunque `clientes` cambie de estructura.

**`SECURITY DEFINER` y `session_user`.** El disparador `trg_auditoria_clientes` (`AFTER INSERT OR UPDATE OR DELETE … FOR EACH ROW`) llama a una función `SECURITY DEFINER`. Así `app_ventas` provoca que se escriba en la auditoría sin tener acceso al esquema (`permiso denegado al esquema auditoria`). Como dentro de la función `current_user` es el propietario, `usuario_efectivo` sale `postgres`; la identidad útil es `usuario_sesion` (`session_user`). La función fija `search_path = pg_catalog, public` para evitar que se sustituyan objetos con privilegios del propietario.

**Resultado del incidente auditado** (`evidencias/11`): `id_evento 1`, 2026-11-07 21:34:27.041, `usuario_sesion = app_ventas`, aplicación `app-ventas-web`, IP `127.0.0.1`, RFC `GAMA780912XYZ → GAMA780912ZZZ`. La bitácora coincide (línea 491). Se pudo restaurar el valor anterior con un `UPDATE` acotado. Las altas y bajas también quedan con la fila completa (Pedro Ruiz, eventos 2 y 3), incluso después de borrarla.

## 5. Limitaciones

- **Lecturas.** `soporte_ana` leyó nombre, RFC y teléfono sin dejar rastro (`evidencias/14`): `mod` no registra `SELECT` y no hay disparador para lecturas. Alternativas: `log_statement = 'all'` (volumen y datos sensibles en el archivo), un acceso solo por función que registre su uso, o pgaudit (Parte C, no realizada).
- **Volumen.** Un `UPDATE` sin `WHERE` produjo 1 línea en la bitácora y 5 filas en la auditoría. Con un millón de registros serían un millón de filas con antes y después.
- **Administrador con control total.** El administrador desactivó el disparador, modificó el RFC y lo reactivó: el cambio no quedó en la auditoría (conteo 3 antes y después). Quedó solo la bitácora (líneas 531–533) y la discontinuidad de valores (`ZZZ` en el evento 1 contra `GHI` como valor anterior en el evento 8). Ningún mecanismo dentro del mismo servidor protege contra quien lo controla por completo.
- **Rol compartido.** La bitácora y la auditoría identifican el rol (`app_ventas`), no a la persona; `application_name` lo declara el cliente y puede falsificarse.
- **Eventos previos a la configuración.** Los cambios de RFC de las Actividades 3 y 7 no tienen sentencia registrada; su valor anterior no consta.
- **Parámetros.** No se observó el mensaje de cambio de parámetro al recargar la configuración, por lo que ese cambio solo se demuestra con `pg_settings` y la sentencia `ALTER SYSTEM` posterior.
- **Alcance de la vista.** `dba.bitacora` solo lee el archivo vigente; los cuatro archivos anteriores de `log/` no entran en ella.

## 6. Riesgos de la bitácora

- **Secretos expuestos.** `CREATE ROLE … PASSWORD '…'` dejó la contraseña en claro en la línea 355, y eliminar el rol no la borra. Se sustituyó por `<REDACTED>` al exportar (la propia consulta de exportación también contenía el secreto, línea 566, y quedó sustituida).
- **Pérdida.** La bitácora vive en el mismo servidor que la produce: una reinstalación, la rotación o un administrador con acceso pueden eliminarla o alterarla. Se exportó el archivo y se calculó su SHA-256; el hash no impide la modificación, solo permite detectarla si se guarda en un lugar distinto del servidor y de quien opera la base. NIST SP 800-92 recomienda conservar y proteger los registros de forma centralizada.
- **Acceso de terceros.** La bitácora contiene datos personales y direcciones; leerla con SQL exige un rol que pueda leer archivos del servidor, por lo que `dba.bitacora` y el archivo deben limitarse a un rol de auditoría. La auditoría contiene RFC e historial de registros borrados, con la misma o mayor clasificación que `clientes`.
- **Retención.** No se definió un plazo formal (se completa en el LAB-03). Propuesta preliminar: conservar la bitácora y la auditoría el tiempo que exijan las obligaciones legales y de auditoría de la empresa, con revisión del área de cumplimiento y depuración autorizada por alguien distinto del DBA operador.

## 7. Cronología y conclusión

La cronología completa (23 eventos) está en `evidencias/15-cronologia.md`. Resumen de lo que se puede demostrar:

- **Cambio de RFC del 21:34:27 (Actividad 12):** `app_ventas`, `app-ventas-web`, `127.0.0.1`, de `XYZ` a `ZZZ`.
- **Cambio de teléfono del 21:34:09:** `app_ventas`, sin valor anterior.
- **Cambio del administrador con el disparador desactivado (21:34:28):** `postgres`, solo por la bitácora; sin valor anterior.
- **Huecos:** cambios de RFC de las Actividades 3 y 7, la lectura de `soporte_ana`, los `ALTER SYSTEM` iniciales y el valor previo de los cambios sin disparador.

**Conclusión.** Con la configuración final (`log_statement = mod`, prefijo completo y disparador de auditoría) **sí puede demostrarse quién cambió un dato sensible, cuándo, desde qué IP y aplicación, y qué valor tenía antes, para los cambios hechos por una cuenta sin privilegios de propietario después de configurar la auditoría**. No puede demostrarse para los cambios anteriores a la configuración, ni para las lecturas, ni para el administrador cuando desactiva el disparador (en ese caso solo queda la sentencia en la bitácora, sin valor anterior). Cubrir el último caso requiere controles administrativos y externos: bitácoras enviadas a un sistema administrado por otra área, y separación entre quien opera la base y quien custodia la evidencia.

## Reflexión

1. **¿Por qué la auditoría no puede configurarse después de un incidente para investigarlo?** Porque solo registra lo que ocurre después de activarse; en la Actividad 3 el cambio ocurrió sin rastro y no pudo reconstruirse.
2. **¿Por qué conviene que la bitácora la administre el propio servidor?** Con el colector activo la ubicación y el formato no dependen del mecanismo de despliegue, y se puede leer con funciones del motor en cualquier plataforma.
3. **¿Por qué el prefijo de línea es tan importante como el nivel de `log_statement`?** Sin `%u`, `%d`, `%a` y `%h`, una línea dice qué ocurrió pero no quién ni desde dónde; con el prefijo `%t` original, solo las líneas de conexión mostraban al usuario.
4. **¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?** La sentencia dice qué se pidió (una línea para un `UPDATE` masivo) y el disparador guarda el valor anterior y nuevo de cada fila (cinco filas para el mismo `UPDATE`).
5. **¿Qué evidencia ofrece `pg_stat_activity` que no ofrece la bitácora, y viceversa?** La vista muestra el estado actual (quién está conectado y qué ejecuta ahora); la bitácora conserva la historia después de que la sesión terminó.
6. **Si el administrador puede cambiar `log_statement` a `none` y desactivar el disparador, ¿quién audita al administrador?** Debe auditarlo alguien ajeno al servidor: un sistema externo de bitácoras bajo otra área, con procedimientos de cambios y doble control. En esta práctica solo la bitácora local y la ruptura de la cadena de valores delataron el cambio.
