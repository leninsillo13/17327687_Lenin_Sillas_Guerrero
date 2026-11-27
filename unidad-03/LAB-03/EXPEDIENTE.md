# Expediente de auditoría interna — Base comercial

**Comercializadora Norte S.A. de C.V.** · Materia: Gestión de Seguridad y Desempeño de Bases de Datos · Unidad III
**Fecha del expediente:** 2026-11-25 · **Responsable:** Lenin Sillas Guerrero (17327687), quien actúa como DBA y custodio (ver L-07)

Convenciones: las horas están en America/Mexico_City (CST, UTC−6). «Línea N» es el número de línea del archivo de bitácora indicado; en `postgresql-2026-11-07_211832.log` coincide con `bitacora-lab01.log` de LAB-01. Las rutas de evidencia son relativas a `LAB-03/evidencias/`. Los RFC se muestran enmascarados o por sufijo.

## 1. Alcance

| Sistema | Versión y despliegue | Ubicación |
|---|---|---|
| PostgreSQL | **18.6** (x86_64-windows, instalador EDB), base `comercial`, colector de bitácora activo | `localhost:5432`, `C:/Program Files/PostgreSQL/18/data`, equipo `DESKTOP-R2B8AMH` |
| MongoDB | **7.0.48 Community**, contenedor Docker `dba-u3-mongo` (imagen `mongo:7`), autenticación habilitada, `bindIp: *` | `localhost:27017` |

- **Periodo revisado:** eventos del 2026-11-07 al 2026-11-21. La bitácora de PostgreSQL disponible comienza el 2026-10-17 (consulta H0 de `sql/04`). Los eventos de MongoDB son del 2026-11-15.
- **Diferencia con la guía:** la guía asume PostgreSQL 16; este servidor es 18.6 y escribe los mensajes en español (`sentencia:`, `conexión autorizada`). `log_connections` es una lista de eventos en esta versión (LAB-01/evidencia 01).
- **Fuera de alcance:** respaldo y restauración (Unidad V), el ambiente de desarrollo y pruebas, y la aplicación `app-ventas-web`.
- **Ambiente:** la Unidad I no se realizó, por lo que no se cita su definición. Se adopta la definición de trabajo de `politicas/POL-06-cambios-produccion.md`: *ambiente* es el conjunto de servidor, base de datos, cuentas y datos que se usa con un propósito y un nivel de riesgo determinados (desarrollo, pruebas o producción, los tres valores de `gobierno.solicitudes_cambio`). En este laboratorio la base `comercial` se trata como producción simulada (L-07).

## 2. Configuración de auditoría (A3)

| Mecanismo | Configuración | Evidencia |
|---|---|---|
| Colector de bitácora (PostgreSQL) | `logging_collector = on`; 15 archivos en `log/`, desde 2026-10-17 | `E1-configuracion-registro.txt`; `pg_ls_logdir()` (consulta H0 de `sql/04`) |
| Conexiones y desconexiones | `log_connections = on`, `log_disconnections = on` | E1 |
| Sentencias | `log_statement = mod` (DDL y modificaciones; **no** `SELECT`). Se pasó a `mod` con `ALTER SYSTEM` el 11-07 21:34:06.664 | E1; línea 377 de `postgresql-2026-11-07_211832.log` |
| Prefijo de línea | `%m [%p] user=%u db=%d app=%a client=%h ` (hora con milisegundos, PID, usuario, base, aplicación, cliente) | E1; LAB-01/evidencia 04 |
| Auditoría del dato | Disparador `trg_auditoria_clientes` (`AFTER INSERT OR UPDATE OR DELETE`, por fila) que escribe en `auditoria.cambios_clientes` la fila completa antes y después. Habilitado hoy (`tgenabled = O`) | `E3-disparadores.txt`; LAB-01/evidencia 11 |
| Registro de cambios | `gobierno.solicitudes_cambio` | `sql/04-registro-cambios.sql`; `06-conciliacion.md` |
| MongoDB: perfilador | Nivel 2 (`slowms 100`, `sampleRate 1`), colección limitada `system.profile` | `E6-mongodb/system-profile.json`; LAB-02/evidencia 03 |
| MongoDB: bitácora de `mongod` | Salida estándar del contenedor; MongoDB **Community: sin auditoría nativa** (`buildInfo.modules = []`) | `E6-mongodb/bitacora-mongod.log`; LAB-02/evidencia 01 |
| MongoDB: instantáneas de privilegios | Control compensatorio; detecta **qué** rol cambió, no quién ni la hora exacta | `E6-mongodb/09-comparacion.md` |

La configuración de E1 es la de hoy. Que estuviera vigente durante todo el periodo no está demostrado por completo (ver L-08).

## 3. Bitácora interpretada (A3, A5)

Seis eventos, con el formato del LAB-01 (Actividad 17). Archivo base: `E5-rotados/postgresql-2026-11-07_211832.log` (ER), salvo el último.

| # | Fecha y hora | Usuario / aplicación / origen | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Qué prueba | Fuente |
|---|---|---|---|---|---|---|---|---|
| 1 | 2026-11-07 21:34:27.041 | `app_ventas` / `app-ventas-web` / 127.0.0.1 | 3 (María García) | Modificación de datos | `UPDATE clientes SET rfc=…` sobre `id = 3`; sufijo del RFC `XYZ → ZZZ` | Sí | Quién (la cuenta, no la persona), cuándo, desde dónde, con qué aplicación y **valor anterior y posterior**. No prueba quién la operaba ni si estaba autorizado | ER línea 491; `auditoria.cambios_clientes` id_evento 1 |
| 2 | 2026-11-07 21:34:28.032–.037 | `postgres` / `psql` / 127.0.0.1 | 3 | Estructura y modificación | `DISABLE TRIGGER trg_auditoria_clientes`, `UPDATE … rfc` (sufijo `GHI`) y `ENABLE TRIGGER`, en 5 ms | Sí | Que el administrador desactivó la auditoría y cambió un dato **sin que quedara en la tabla de auditoría** (el conteo no cambió y el `valores_antes` del evento 8 es `GHI`, no `ZZZ`) | ER líneas 531–533; id_evento 1 y 8 |
| 3 | 2026-11-07 21:34:00.091 | `postgres` / `psql` / 127.0.0.1 | — | Privilegio (gestión de roles) | `CREATE ROLE rol_temporal … PASSWORD '<REDACTED>'`; luego `DROP ROLE` (línea 356) | Sí | Que el servidor **registró una contraseña en claro**; borrar el rol no la quita del archivo | ER líneas 355–356 |
| 4 | 2026-11-07 21:34:13.009–.012 | `soporte_ana` / `psql` / 127.0.0.1 | 5 | Error de autorización | `DELETE FROM clientes WHERE id = 5` → «permiso denegado a la tabla clientes» | No | Que el control de acceso funcionó y que el **intento** queda registrado; el dato no cambió | ER líneas 395–397 |
| 5 | 2026-11-07 21:34:31.364 | `soporte_ana` / 127.0.0.1 | 3 | Lectura de datos (hueco) | Consulta de nombre, RFC y teléfono; solo quedan `conexión autorizada` y `desconexión` | Sí | Que **las lecturas no se registran** con `mod`: se sabe que hubo sesión, no qué leyó | ER líneas 544–546 (LAB-01/evidencia 14) |
| 6 | 2026-11-21 22:19:57.510 | `postgres` / `psql` / `::1` | — | Estructura (cambio autorizado) | `ALTER TABLE clientes ADD COLUMN canal_alta`, dentro de la ventana del folio CAM-2026-014 | Sí | Que el cambio coincide con una solicitud registrada. No prueba que el Comité lo aprobara de forma independiente (H-05) | `postgresql-2026-11-19_214623.log` línea 87; `gobierno.solicitudes_cambio` |

### Incidente del RFC de María García

Cinco cambios al RFC del cliente 3 (cuatro en PostgreSQL, LAB-01, y uno en MongoDB, LAB-02), con distinta evidencia:

| Momento | ¿Evidencia de quién y cuándo? | ¿Valor anterior? |
|---|---|---|
| 11-07 21:33:46 | **Ninguna**: `log_statement = none`; solo una sesión de `app_ventas` (líneas 288–290) | No |
| 11-07 21:34:03 | **Ninguna directa**: nivel `ddl`; solo una sesión de `app_ventas` (365–367) | No |
| 11-07 21:34:27.041 | **Sí**: evento 1 y línea 491 (`app_ventas`, `app-ventas-web`, 127.0.0.1) | Sí (sufijo `XYZ`) |
| 11-07 21:34:28.034 | **Parcial**: línea 532 (`postgres`, `psql`); no está en la auditoría | No |
| 11-15 22:45:04 (MongoDB) | Parcial: `system.profile` (`app_ventas@comercial`, `app-ventas-web`, 172.17.0.1) | No: el perfilador guarda el valor nuevo |

Respuesta a Dirección: solo se puede demostrar quién, cuándo y desde dónde en los cambios con `mod` y disparador activos. Los dos primeros cambios de PostgreSQL no tienen prueba; lo que consta es la coincidencia de una sesión de la aplicación, que es un indicio y no una prueba. La IP 172.17.0.1 de MongoDB es la puerta de enlace de Docker, no un equipo remoto.

## 4. Elementos de gobierno (A1, A2)

- **Responsables** (`02-responsables.md`): propietario del conjunto `clientes`: Gerencia Comercial; custodio: DBA; la corrección de cada campo la aprueba su responsable de la Unidad II (RFC y código postal: Facturación; nombre, correo y teléfono: Atención al cliente; edad y ciudad: Analítica). La auditoría y las bitácoras son propiedad de Auditoría interna, no de quien opera los datos.
- **Catálogo** (`04-catalogo.md`): 8 conjuntos en PostgreSQL y MongoDB (CAT-01 a CAT-08), con propietario, custodio, clasificación, finalidad y conservación. El propietario técnico de todos los objetos es `postgres`; no es el propietario del dato.
- **Diccionario** (`03-diccionario.md`, `diccionario-clientes.csv`): 11 columnas con `COMMENT` (0 sin comentario). Datos personales: nombre, correo, teléfono, RFC, edad, ciudad y código postal. Los controles que la Unidad II propone (vista enmascarada, cifrado del RFC) **no se encontraron** en esta base (H-03).

## 5. Conservación (A3)

Detalle y justificación en `05-conservacion.md`; los periodos son propuestas razonadas, no plazos legales.

| Registro | Periodo propuesto | Al vencer |
|---|---|---|
| Accesos de PostgreSQL | 12 meses | Eliminar con acta |
| Cambios de privilegios y estructura | 24 meses | Eliminar con acta |
| Modificaciones de datos | 12 meses | Eliminar con acta |
| `auditoria.cambios_clientes` | 24 meses metadatos; 12 meses valores | Anonimizar valores; luego eliminar |
| Bitácora de `mongod` | 12 meses | Eliminar con acta |
| `system.profile` (exportado) | 6 meses | Eliminar con acta |
| Instantáneas de privilegios | 24 meses | Eliminar con acta |

Todos los plazos legales están pendientes de confirmar con el área jurídica (protección de datos personales y conservación fiscal de la facturación).

## 6. Políticas (A4)

| Política | Regla (resumen) | Evidencia que existe hoy | Evidencia que **no** existe hoy |
|---|---|---|---|
| POL-01 Acceso | Todo acceso o cambio de privilegios con solicitud aprobada por el propietario; revisión trimestral | E2; bitácora (líneas `sentencia: GRANT/REVOKE`); `gobierno.solicitudes_cambio` | Acta de revisión trimestral |
| POL-02 Respaldo | Respaldo diario, prueba de restauración trimestral verificada por otra persona | — | Todo: registro de respaldos y de pruebas (Unidad V) |
| POL-03 Retención | Periodos de la sección 5; ninguna bitácora se elimina antes | `05-conservacion.md`; hashes | Acta de eliminación (aún no vence nada) |
| POL-04 Restauración | Folio aprobado, copia previa y verificación posterior | E2 y E3 como comprobaciones | Actas de restauración (ninguna practicada) |
| POL-05 Datos sensibles | Justificación aprobada, auditoría revisada mensualmente, redacción de bitácoras | E4, E5, diccionario | Registro de **lecturas**; hoy **se incumple** el apartado de secretos (H-02) |
| POL-06 Cambios en producción | Folio antes, ventana durante, verificación y conciliación después | `gobierno.solicitudes_cambio`; `06-conciliacion.md`; E3 | Conciliación mensual por una persona distinta del DBA |

## 7. Conciliación de cambios (A5)

Detalle en `06-conciliacion.md`. De las 23 sentencias de estructura y privilegios extraídas de todos los archivos (consulta H1 de `sql/04`): **1 tiene folio** (`ALTER TABLE clientes ADD COLUMN canal_alta`, CAM-2026-014, línea 87) y **22 no**. De las 22, 3 fallaron (líneas 402, 520 y 597) y 19 tuvieron efecto: 14 de preparación del LAB-01, 3 del arranque de este laboratorio y 2 que constituyen el hallazgo de manipulación (líneas 531 y 533). El periodo anterior al 2026-11-07 ~21:33:52 no es conciliable porque no se registraban sentencias.

## 8. Hallazgos

| ID | Hallazgo | Fuente | Severidad | Impacto | Recomendación | Decisión requerida de |
|---|---|---|---|---|---|---|
| H-01 | El administrador desactivó el disparador de auditoría y cambió un RFC **sin que quedara en la tabla de auditoría**. Antes, `app_ventas` lo intentó y falló | ER líneas 520–521, 531–533; id_evento 1 y 8; `06-conciliacion.md` | **Alta** | La auditoría del dato depende de una sola cuenta. Un cambio pudo quedar sin valor anterior ni autor en la tabla | Separar funciones: custodia de la auditoría fuera del DBA; envío externo de bitácoras; exigir folio para desactivar disparadores; revisar diferencias entre bitácora y auditoría | Auditoría interna y Dirección |
| H-02 | Contraseña en texto claro en la bitácora (`CREATE ROLE … PASSWORD`). El archivo original del servidor sigue conteniéndola; las copias exportadas están redactadas | ER línea 355; consulta H4 de `sql/04` | **Alta** | Quien lea `log/` obtiene una credencial. Mitigantes: el rol se eliminó (línea 356) y era una contraseña de práctica | No escribir contraseñas en SQL (usar `\password`); restringir la lectura de `log/`; rotar cualquier contraseña real expuesta; redactar antes de compartir | Auditoría interna y Seguridad |
| H-03 | Los privilegios vigentes no coinciden con la matriz de la Unidad II: `soporte_ana` tiene `SELECT` sobre toda la tabla (ve RFC, edad y código postal); `app_ventas` tiene `UPDATE` sobre toda la tabla y no hay rol equivalente en U2; **no existe la vista enmascarada** ni el cifrado del RFC | `E2-privilegios.txt`; consulta de vistas de `sql/03` (solo `dba.bitacora`); `gobierno-datos.md` (U2) | **Alta** | Incumple el mínimo privilegio. Las lecturas del RFC por soporte no se auditan (H-07) | Cambiar a privilegios por columna o vistas por rol; definir el rol de la aplicación de ventas | Gerencia Comercial (propietaria) |
| H-04 | No existía un registro de cambios: de 23 sentencias, solo 1 tiene folio; 19 cambios con efecto no tienen solicitud, entre ellos el cambio del nivel de registro de la propia auditoría (línea 377) | `06-conciliacion.md` | Media | No se puede demostrar que los cambios estaban autorizados. En este laboratorio la mayoría es preparación, pero en una organización serían cambios no autorizados | Regularizar con folios retroactivos marcados como tales; aplicar POL-06 desde ahora | Comité de cambios |
| H-05 | El folio CAM-2026-014 lo registró y ejecutó el mismo DBA, en la misma sesión, con la aprobación declarada un día antes; la tabla es escribible por `postgres` | `sql/04-registro-cambios.sql`; línea 87 | Media | La aprobación no es verificable de forma independiente | Que el Comité registre y apruebe; el DBA solo consulta y ejecuta dentro de la ventana | Comité de cambios |
| H-06 | Calidad de datos: duplicado (ids 1 y 7), RFC incompleto (7) y ausente (8), correo, edad, teléfono y código postal inválidos (8), ciudad con variantes | `01-calidad.md` (C1–C8) | Media | Facturas con RFC erróneo, contactos inalcanzables, analítica sesgada | Corrección por los responsables de campo; restricciones `CHECK` y `UNIQUE` con `NOT VALID` y validación posterior | Gerencia Comercial; Facturación; Atención al cliente; Analítica |
| H-07 | Las lecturas de datos sensibles no se auditan: `soporte_ana` leyó nombre, RFC y teléfono y solo quedan conexión y desconexión | ER líneas 544–546 | Media | No se puede saber quién leyó qué | Evaluar `pgaudit` o entregar el dato por una función que registre su uso; evitar `log_statement = all` | Gerencia Comercial y Seguridad |
| H-08 | Huecos de evidencia: antes de ~21:33:52 del 11-07 no se registraban sentencias; los dos primeros cambios del RFC no tienen prueba; los archivos de octubre no contienen DDL; la creación original de `dba.bitacora` no consta | consulta H0 de `sql/04` y H1; LAB-01/evidencia 15 | Media | El incidente original de Dirección no se puede resolver con evidencia | Declararlo (hecho aquí) y mantener `mod` desde el arranque del servidor | Auditoría interna |
| H-09 | Bitácora, auditoría y datos viven en el mismo servidor y bajo el mismo custodio, sin copia externa. 7 cierres inadecuados del servidor entre el 11-07 y el 11-19 | consulta H7 de `sql/04` | Media | Pérdida de evidencia por falla o manipulación; la continuidad del registro no está garantizada | Exportación periódica con hash a un repositorio de Auditoría interna; servicio apagado correctamente | Auditoría interna y Seguridad |
| H-10 | Conflicto retención contra supresión: los datos completos de Pedro Ruiz (cliente eliminado) siguen en la auditoría (eventos 2 y 3). Los plazos legales no están confirmados | LAB-01/evidencia 12; `05-conservacion.md` | Media | Conservación de datos personales sin base definida | Aplicar la anonimización a los 12 meses (POL-03); confirmar plazos | Gerencia Comercial, Auditoría interna y el área jurídica |
| H-11 | `clientes` existe en PostgreSQL y en MongoDB y puede divergir el RFC: sufijo `GHI` en PostgreSQL (línea 532) y `XYZ` en MongoDB (`system.profile`, 11-15). **No verificado** que sean el mismo cliente | `04-catalogo.md`; `E6-mongodb/system-profile.json` | Media | Dos valores de RFC sin una fuente de verdad | Un solo propietario (Gerencia Comercial) y Facturación como autoridad del RFC | Gerencia Comercial y Facturación |
| H-12 | La bitácora mezcla codificaciones (mensajes del servidor en LATIN1/WIN1252 y sentencias en UTF-8). E5 se convierte desde LATIN1: los acentos de algunas sentencias se ven alterados y el hash es de la copia, no del original | consulta H9 de `sql/04`; `06-conciliacion.md` §6 | Baja | Evidencia legible pero no idéntica al archivo original | Conservar también los archivos originales con su hash; documentar el procedimiento de conversión | DBA y Auditoría interna |
| H-13 | Rechazos de autenticación (`pg_hba.conf` sin regla, contraseñas incorrectas) que la bitácora no distingue de un ataque; algunos con el prefijo antiguo sin cliente | consulta H6 de `sql/04`; LAB-01/evidencia 15 | Baja | Intentos de acceso sin clasificar | Mantener el prefijo completo; revisar los rechazos en la revisión mensual | Auditoría interna |
| H-14 | Los objetos `auditoria.cambios_clientes` y `dba.bitacora` no tienen `COMMENT`; el servidor es 18.6 y no 16 como asume la guía | `04-catalogo.md` | Baja | Catálogo incompleto | Agregar los comentarios con folio | Gerencia Comercial |
| H-15 | Limitaciones de los controles (sección 9): sin auditoría nativa en MongoDB Community, administrador que puede desactivar la auditoría, sin copia externa, auto-revisión | Sección 9 | Media | Riesgo residual del que hay que dejar constancia | Aceptación formal o mitigación según la sección 9 | Ver sección 9 |

Ningún hallazgo se corrigió ni se eliminó del registro: los registros 7 y 8 siguen en `clientes` y los cambios sin folio siguen en la conciliación.

## 9. Limitaciones conocidas y riesgos aceptados (A6)

### Verificado en los laboratorios

| ID | Limitación | Evidencia | Debe aceptarla formalmente |
|---|---|---|---|
| L-01 | MongoDB Community no tiene auditoría nativa; el perfilador no registra cambios de privilegios ni valores anteriores. El control compensatorio detecta qué rol cambió, no quién ni cuándo | `E6-mongodb/09-comparacion.md`; LAB-02/evidencia 01 | Dirección, con Auditoría interna |
| L-02 | Con `log_statement = mod` no se registran las lecturas (`SELECT`) | LAB-01/evidencia 14 (líneas 544–546) | Gerencia Comercial (propietaria de `clientes`) |
| L-03 | El administrador puede desactivar el disparador y la auditoría; el cambio queda solo en la bitácora local | ER líneas 531–533 | Dirección y Auditoría interna |
| L-04 | Bitácora y auditoría en el mismo servidor, bajo el mismo custodio, sin copia externa; el servidor se cerró de forma inadecuada 7 veces | consulta H7 de `sql/04` | Seguridad de la información y Auditoría interna |
| L-05 | La bitácora puede contener secretos y datos personales; toda extracción requiere revisión y redacción | ER línea 355; E5 | Seguridad de la información |
| L-06 | Codificación mixta en la bitácora; E5 es una conversión | H-12 | DBA y Auditoría interna |
| L-07 | Una sola persona preparó el entorno, hizo los cambios, registró los folios y concilió. Una sola instancia hace de producción | `06-conciliacion.md` | Auditoría interna |
| L-08 | No está demostrado que E1 estuviera vigente todo el periodo; solo hay indicios (formato de línea, línea 377) | `06-conciliacion.md` §5 | Auditoría interna |

### Documentado, no practicado

| ID | Elemento | Estado | Debe aceptarla formalmente |
|---|---|---|---|
| D-01 | Auditoría nativa de MongoDB Enterprise o Atlas (REF-U3-04) | Descrita en el manual; no practicada; el alcance exacto por evento no se afirma | Dirección (decisión de licenciar contra aceptar el riesgo) |
| D-02 | `pgaudit` para registrar lecturas | Mencionado como alternativa en LAB-01; no instalado | Gerencia Comercial y Seguridad |
| D-03 | Envío de bitácoras a un repositorio externo o inmutable | Propuesto en POL-03; no implementado | Seguridad de la información |
| D-04 | Respaldo y restauración (POL-02, POL-04) | Políticas escritas; sin procedimiento ni evidencia (Unidad V) | Gerencia Comercial |

## 10. Índice de evidencias

Hashes SHA-256 de las evidencias técnicas, calculados con `sha256sum` (`INDICE-HASHES.txt`). Los documentos redactados (`01` a `06`, `EXPEDIENTE.md`, políticas, SQL) son texto versionado en el repositorio y se identifican por su commit.

| Archivo | SHA-256 |
|---|---|
| `E1-configuracion-registro.txt` | `55ba86aa18149efe346560930249c84e975b5639331bffee15907870fdff4c69` |
| `E2-privilegios.txt` | `a1134d2dc970f1107a29325c9ab98ad45e90ee2507c76d3edac407001a40cbc8` |
| `E3-disparadores.txt` | `38db1b732e672e255acb0cb01a22a42cb6686c9d47a229ef39b166cf0695f060` |
| `E4-muestra-auditoria.txt` | `00d46889526fe7acd431a45604b083b5cfe8da6dd0a0f6d9f839f5bc91a242c2` |
| `E5-bitacora-postgresql.log` | `8a1f76e0493b9564ec7ae85c3d5f3b25fe77f4a74a24fb79bb7be72e7e20f5ad` |
| `E5-bitacora-postgresql.sha256` | `25f0bb2f3e52661ce61d14fd8be75ab502da0345791d93d3274c0899cd79998d` |
| `E5-rotados.sha256` | `10940e7900fb4e0fda18471c6a7bbb2a6256e8649b9f6703cb46700c7b52b13d` |
| `E5-rotados/postgresql-2026-10-17_225408.log` | `c6e6881ffd831ba6bf2a76133a5f13f25fe7be8868e0672096bf7dea5e6b69a6` |
| `E5-rotados/postgresql-2026-10-18_000000.log` | `66344b6cd3a69465679a39668d247b91d3ec89895738e0a32a31d98901ae8056` |
| `E5-rotados/postgresql-2026-10-19_000000.log` | `bbd71f6e337c36d93c4de5389338a180e8a2ab17b79fa9a7b397f9f196681412` |
| `E5-rotados/postgresql-2026-10-25_003359.log` | `ad5549ece2695d05d929834bbb5ae5a1f62cd9444aa0d74269b433e10ab4a373` |
| `E5-rotados/postgresql-2026-11-07_211832.log` | `4e4e8b6397eeee2c1f6621569f91d2ebc77c8d2e39fd19106601bc9616ad432c` |
| `E5-rotados/postgresql-2026-11-07_235304.log` | `2b983d264c5890f701bb93421b395314a4691965f147fafe9ab9d9ed340f5bdf` |
| `E5-rotados/postgresql-2026-11-08_131403.log` | `bc0bad8eb09c14079ec7e47b7ab7743a0a38702d3bbf21e068056435da42b0dd` |
| `E5-rotados/postgresql-2026-11-08_201009.log` | `4f59bcf59d24a5ed0f4b25ee424c067c81f25af96f55b94a8974c1a7bda76645` |
| `E5-rotados/postgresql-2026-11-10_213627.log` | `a62717a68f4bb2a1caab84f5830ce49f01f84994ee52c6cfd7118549da3beeff` |
| `E5-rotados/postgresql-2026-11-10_215225.log` | `3aa167ba81c995e382e69621e0ae19666382e107777fc1fe8ab106748e40c078` |
| `E5-rotados/postgresql-2026-11-15_222526.log` | `7535e8934adfe25fd5cab66aae45329aa914666cecaf7fc66b663d9ef097a7d0` |
| `E5-rotados/postgresql-2026-11-16_144038.log` | `a63d0ebbe3a2e5c31df4b5e2762c10566fc48f66b18723e158eadabd54f1dbe6` |
| `E6-mongodb/09-comparacion.md` | `6792add0a0f40cd322db7d09acb995fc98c1e9c92e6735f801b48501d475ef87` |
| `E6-mongodb/bitacora-mongod.log` | `6a6e6cbdff889cd5859b9e56bc1913091ff5819c3e753be784b3d01c0cef34c6` |
| `E6-mongodb/hashes.sha256` | `730e93eba023c51a42c1246bfca37c066cd5f16472d3fe90610884c026c51e1f` |
| `E6-mongodb/system-profile.json` | `ee643d3326e665662da70e7a06ee8ac9135a61f87268e7125ae112850a7f5790` |
| `diccionario-clientes.csv` | `8f5e68a92326f45677169ce121d5072c82a633466833ff2d172ebc53add89205` |

Otros archivos: `01-calidad.md` a `06-conciliacion.md`, `politicas/POL-01` a `POL-06`, `sql/01` a `sql/04`. Hashes de la bitácora del LAB-01: `LAB-01/evidencias/bitacora-lab01.sha256`.

## Anexo — Preguntas de reflexión

1. **¿Por qué el gobierno de datos no es «burocracia» aquí?** Porque el problema inicial no fue técnico: el RFC cambió y nadie podía decir quién lo hizo, con qué autorización ni qué valor tenía. Sin propietario, política y registro, un cambio no se puede calificar de indebido (H-04).
2. **Propietario técnico frente a propietario del dato.** El técnico es `postgres`, dueño del objeto en el motor; el del dato es Gerencia Comercial, que decide uso, acceso y eliminación. El DBA opera, no decide.
3. **¿Por qué una política sin evidencia no supera una auditoría?** Porque es una afirmación. POL-02 y POL-04 están escritas, pero no existe ningún respaldo ni restauración que las demuestre (sección 6).
4. **¿Qué parte sería la más difícil de mantener?** La conciliación y la matriz de privilegios, que cambian con cada cambio. Se resolvería con revisión mensual por Auditoría interna y consultas repetibles como las de `sql/04`.
5. **¿Qué hallazgo tiene mayor impacto?** H-01: invalida la confianza en toda la tabla de auditoría, porque basta una cuenta para desactivarla sin dejar rastro en ella.
6. **¿Por qué documentar una limitación es preferible a ocultarla?** Porque una auditoría que la descubre por su cuenta pierde la confianza en todo lo demás; declarada, permite decidir quién acepta el riesgo y cuándo se mitiga.
