# Evidencia 06 — Conciliación de cambios y evidencias técnicas

**Estudiante:** Lenin Sillas Guerrero
**Actividades:** 7 (registro de cambios y conciliación) y 8 (evidencias técnicas E1–E6)
**Fecha:** 2026-11-21 (ejecución) · documento: 2026-11-25
**Archivo SQL:** `sql/04-registro-cambios.sql` (incluye las consultas H0 a H10 sobre la bitácora)

## 1. Registro de cambios

Se creó `gobierno.solicitudes_cambio` (esquema sin acceso para `PUBLIC`) y se registró el folio **CAM-2026-014** (agregar `canal_alta` a `clientes`; solicitado por Gerencia Comercial, aprobado por el Comité de cambios, ambiente `produccion`). La verificación de ventana devolvió `dentro_de_ventana = t`. El `ALTER TABLE` se ejecutó el 2026-11-21 22:19:57.510, dentro de la ventana, y quedó en la línea 87 del archivo `postgresql-2026-11-19_214623.log`.

Limitación del folio: lo registró el propio DBA (`postgres`), en la misma sesión que ejecutó el cambio, con una fecha de aprobación de un día antes. La aprobación del Comité no es verificable de forma independiente (H-05).

## 2. Qué se conciliaba y por qué hubo que leer todos los archivos

`dba.bitacora` solo lee el archivo vigente. Los cambios del LAB-01 están en un archivo rotado, así que la consulta sobre la vista devolvió 0 filas. Las consultas H0 a H10 de `sql/04` leen todos los archivos con `pg_ls_logdir()`. Además, el servidor está en español: las líneas dicen `sentencia:`, no `statement:`, y la extracción acepta ambas.

## 3. Conciliación (23 sentencias de estructura y privilegios)

Referencias: «N» es la línea del archivo `postgresql-2026-11-07_211832.log` (coincide con `bitacora-lab01.log` del LAB-01) o del vigente `postgresql-2026-11-19_214623.log` (21-nov). Usuario `postgres` salvo indicación. Los folios solo existen desde el 2026-11-21.

| Línea | Momento (CST) | Usuario | Sentencia | Folio | ¿Autorizado? | Hallazgo |
|---|---|---|---|---|---|---|
| 348 | 11-07 21:33:59.863 | postgres | `REVOKE UPDATE ON clientes FROM soporte_ana` | — | No | Preparación LAB-01. Sin folio (H-04) |
| 349 | 21:33:59.865 | postgres | `GRANT UPDATE ON clientes TO app_ventas` | — | No | Preparación LAB-01. **Privilegio vigente hoy** (E2) sin autorización documentada (H-03) |
| 350 | 21:33:59.867 | postgres | `ALTER TABLE clientes ADD COLUMN segmento` | — | No | Preparación LAB-01. Columna vigente |
| 355 | 21:34:00.091 | postgres | `CREATE ROLE rol_temporal … PASSWORD '<REDACTED>'` | — | No | Preparación LAB-01. **Contraseña en claro en la bitácora** (H-02) |
| 356 | 21:34:00.103 | postgres | `DROP ROLE rol_temporal` | — | No | Preparación LAB-01. No borra el secreto del archivo |
| 377 | 21:34:06.664 | postgres | `ALTER SYSTEM SET log_statement = 'mod'` | — | No | Cambio de configuración de la auditoría sin folio (H-04) |
| 402 | 21:34:13.118 | postgres | `DROP ROLE soporte_ana` | — | No | **Falló** (línea 403: dependencias). Intento sin efecto |
| 434 | 21:34:23.681 | postgres | `CREATE SCHEMA auditoria` | — | No | Preparación LAB-01 (Parte B) |
| 435 | 21:34:23.684 | postgres | `REVOKE ALL ON SCHEMA auditoria FROM PUBLIC` | — | No | Preparación LAB-01 (Parte B) |
| 436 | 21:34:23.684 | postgres | `CREATE TABLE auditoria.cambios_clientes` | — | No | Preparación LAB-01 (Parte B) |
| 452 | 21:34:23.807 | postgres | `CREATE OR REPLACE FUNCTION auditoria.registrar_cambio_cliente()` | — | No | Preparación LAB-01 (Parte B) |
| 475 | 21:34:23.828 | postgres | `REVOKE ALL ON FUNCTION … FROM PUBLIC` | — | No | Preparación LAB-01 (Parte B) |
| 476 | 21:34:23.829 | postgres | `CREATE TRIGGER trg_auditoria_clientes` | — | No | Preparación LAB-01 (Parte B) |
| 520 | 21:34:27.711 | **app_ventas** | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes` | — | No | **Intento no autorizado, bloqueado**: línea 521 «debe ser dueño de la tabla». El control funcionó; el intento es un indicio (H-01) |
| 531 | 21:34:28.032 | postgres | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes` | — | No | **Hallazgo grave**: se desactivó el control y se cambió un dato sin auditar (H-01) |
| 533 | 21:34:28.037 | postgres | `ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes` | — | No | Se reactivó 5 ms después de la línea 532 (el UPDATE) |
| 597 | 21:49:18.324 | postgres | `CREATE OR REPLACE VIEW dba.bitacora AS …` | — | No | Falló según LAB-01/evidencia 02 (cambio de ordenamiento de columna); se resolvió con 652 y 653 |
| 652 | 21:56:21.604 | postgres | `DROP VIEW IF EXISTS dba.bitacora` | — | No | Preparación LAB-01. La creación **original** de la vista no consta: `log_statement` era `none` (hueco, H-08) |
| 653 | 21:56:21.610 | postgres | `CREATE VIEW dba.bitacora AS …` | — | No | Preparación LAB-01; la versión vigente sí consta |
| 69 | 11-21 22:19:57.363 | postgres | `CREATE SCHEMA IF NOT EXISTS gobierno` | — | No | Alta del propio registro de cambios, sin folio previo (H-04) |
| 70 | 22:19:57.384 | postgres | `REVOKE ALL ON SCHEMA gobierno FROM PUBLIC` | — | No | Igual |
| 71 | 22:19:57.388 | postgres | `CREATE TABLE IF NOT EXISTS gobierno.solicitudes_cambio` | — | No | Igual |
| 87 | 22:19:57.510 | postgres | `ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20)` | **CAM-2026-014** | **Sí** | — (dentro de ventana; ver limitación del folio, H-05) |

**Resumen.** De las 23 sentencias: **1** tiene folio (4 %); **22** no. De esas 22, **3 fallaron** (402, 520, 597) y 19 tuvieron efecto: 14 de preparación del LAB-01, 3 del arranque de este laboratorio (69, 70, 71) y 2 que son el hallazgo de manipulación (531, 533). Además hay al menos 12 sentencias `COMMENT ON` (H9; la consulta se limitó a 12 filas): solo la de `canal_alta` está cubierta por el folio; las demás modifican metadatos sin folio (Baja).

## 4. Preguntas de la Actividad 7

**1. ¿Qué cambios de la bitácora no tienen folio? ¿Son de preparación o hallazgos?**
Los 22 de la tabla. Los que son preparación del laboratorio se explican por el ejercicio, pero **no se tratan como autorizados**: en una organización real serían 19 cambios de producción sin solicitud. Se reportan como un hallazgo de proceso (H-04: no existía un registro de cambios). Son hallazgos individuales: 531/533 (control desactivado y cambio sin auditar), 520 (intento de desactivarlo desde la aplicación), 355 (secreto en la bitácora), 377 (cambio del nivel de registro sin autorización) y 349 (privilegio de escritura vigente sin respaldo documental).

**2. La desactivación del disparador del LAB-01 (Actividad 14), ¿qué tan grave es? ¿Qué distingue la línea 163 de la 169 de la guía?**
Es grave (Alta): quita el mecanismo que conserva el valor anterior y permite cambiar datos sin dejar rastro en la auditoría. Aquí quedó solo en la bitácora (líneas 531–533) y se detecta por la discontinuidad de la auditoría: el valor posterior del evento 1 (sufijo `ZZZ`) no coincide con el `valores_antes` del evento 8 (sufijo `GHI`), y el conteo de eventos no cambió. Sin la bitácora, nadie lo habría notado. Las líneas 163 y 169 de la guía son nuestras 520 y 531: en la primera, `app_ventas` lo intentó y **falló** por falta de privilegios (el control de acceso funcionó, pero el intento es un indicio); en la segunda, `postgres` lo **ejecutó**: el control de auditoría solo es tan fuerte como la cuenta que lo administra.

**3. ¿Qué limitación tiene esta conciliación si `log_statement` estuvo en `none` durante algún periodo?**
Solo concilia lo que se registró. Antes de las ~21:33:52 del 2026-11-07 (cuando cambia el prefijo de línea) `log_statement` valía `none`, y los archivos de octubre no tienen ninguna sentencia DDL (H1): ese periodo no es conciliable, y las cuatro sentencias `ALTER SYSTEM` iniciales tampoco quedaron. Entre ese momento y las 21:34:06.664 el nivel fue `ddl`, que no registra `UPDATE` (el cambio de RFC de las 21:34:03 no está); desde ahí es `mod`. La ausencia de líneas no prueba que no hubiera cambios. A eso se suman los 7 cierres inadecuados del servidor.

**4. ¿Quién debería realizar la conciliación: el DBA que hizo los cambios u otra persona?**
Otra persona: Auditoría interna, con las extracciones que prepara el DBA. Quien hizo los cambios no debe validar que estaban autorizados. En este laboratorio una sola persona hizo los cambios, registró el folio y concilió: es una limitación declarada (L-07).

## 5. Actividad 8 — Evidencias técnicas

| Evidencia | Archivo | Qué demuestra |
|---|---|---|
| E1 | `E1-configuracion-registro.txt` | `logging_collector`, `log_connections`, `log_disconnections` en `on`; `log_statement = mod`; prefijo `%m [%p] user=%u db=%d app=%a client=%h ` (origen: archivo de configuración) |
| E2 | `E2-privilegios.txt` | `app_ventas`: SELECT, UPDATE; `soporte_ana`: SELECT, ambos sobre `public.clientes` |
| E3 | `E3-disparadores.txt` | `trg_auditoria_clientes` habilitado (`O`) sobre `clientes` |
| E4 | `E4-muestra-auditoria.txt` | 10 eventos (todos los que existen), solo metadatos |
| E5 | `E5-bitacora-postgresql.log` + `.sha256`; `E5-rotados/` + `E5-rotados.sha256` | Bitácora vigente (272 líneas) y 12 archivos rotados, con contraseña redactada y hash |
| E6 | `E6-mongodb/` | `system-profile.json`, `bitacora-mongod.log`, `hashes.sha256`, `09-comparacion.md` copiados de LAB-02 |

**1. Compara E2 con la matriz de roles de la Unidad II. ¿Coinciden? Si no, ¿es un hallazgo?**
No coinciden, y es un hallazgo (H-03). (a) `soporte_ana` tiene `SELECT` sobre toda la tabla, de modo que ve RFC, edad y código postal, que la matriz U2 niega a Atención al cliente; el LAB-01 (evidencia 14) mostró que leyó nombre, RFC y teléfono. (b) `app_ventas` tiene `UPDATE` sobre toda la tabla y la matriz U2 no define un rol equivalente. (c) La vista enmascarada de la U2 no existe en `comercial`. (d) Los roles funcionales `soporte`, `analista`, `dba_lab`, `consulta_lab` y `app_lab` no aparecen en E2; no verifiqué si tienen privilegios por columna (`information_schema.column_privileges`), que E2 no cubre.

**2. ¿Por qué E4 muestra solo metadatos y no `valores_antes` ni `valores_despues`?**
Porque esas columnas contienen la fila completa con datos personales (RFC, correo, teléfono). La evidencia demuestra que el control funciona sin reproducir la tabla de clientes. Se conserva quién, cuándo, desde dónde, qué operación y a qué registro.

**3. ¿Qué evidencia demostraría que E1 estuvo vigente durante todo el periodo y no solo hoy?**
Instantáneas periódicas de `pg_settings` (con fecha y hash) guardadas fuera del servidor, o el archivo de configuración bajo control de versiones. Hoy solo hay indicios: el formato de las líneas (los campos `user= db= app= client=` aparecen desde las 21:33:52.953 del 2026-11-07), la línea 377 (`ALTER SYSTEM SET log_statement = 'mod'`), y que H8 no muestra ningún otro cambio posterior de `log_statement`. No cubre ediciones manuales del archivo de configuración, que no se registran, ni las interrupciones del servidor.

## 6. Notas de calidad de las evidencias

- E5 se exporta leyendo el archivo como bytes y convirtiéndolo desde LATIN1: los mensajes del servidor en Windows no están en UTF-8, pero las sentencias que envía el cliente sí. Por eso aparecen acentos alterados («CÃ³digo») en el texto de algunos `COMMENT`. La conversión es reversible; el hash corresponde a la copia exportada, no al archivo original (H-12).
- El archivo E5 vigente contiene 13 líneas `ERROR:`. Incluyen al menos los errores de codificación de la primera exportación de E5. No las clasifiqué una a una; listarlas es un pendiente (`grep -n "ERROR:" evidencias/E5-bitacora-postgresql.log`).
