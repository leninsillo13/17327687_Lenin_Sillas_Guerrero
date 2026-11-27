# POL-05 — Uso de datos sensibles

**Objetivo:** limitar y poder rastrear el uso de datos personales de clientes (RFC, correo, teléfono, nombre, edad, ciudad y código postal) y evitar que se filtren por las bitácoras o los expedientes.

**Alcance:** columnas clasificadas como dato personal en `evidencias/diccionario-clientes.csv`, `auditoria.cambios_clientes`, bitácoras de PostgreSQL y de `mongod`, `system.profile` y cualquier extracción o expediente derivado.

**Regla:**
1. El acceso al RFC completo y a otros datos personales requiere justificación escrita aprobada por el propietario; soporte usa la vista enmascarada (Unidad II).
2. Las modificaciones de datos sensibles quedan registradas en `auditoria.cambios_clientes` y en la bitácora (`log_statement='mod'`); el DBA revisa mensualmente esos registros contra los accesos aprobados (POL-01).
3. Toda bitácora o extracción se revisa y se le retiran contraseñas y datos personales completos antes de compartirla (como en E5); los expedientes solo muestran metadatos o datos enmascarados.

**Responsable:** decide el propietario del dato (Gerencia Comercial); ejecuta el DBA; revisa Auditoría interna.

**Excepciones:** acceso a datos completos por requerimiento legal o investigación de incidente, autorizado por el propietario y el área jurídica, con folio.

**Evidencia:**
- `evidencias/E4-muestra-auditoria.txt` (solo metadatos) y `evidencias/E5-bitacora-postgresql.log`.
- `evidencias/diccionario-clientes.csv` (clasificación de columnas) y `evidencias/E2-privilegios.txt`.
- Revisión de contraseñas en bitácora: la consulta H4 de `sql/04` muestra una sentencia `CREATE ROLE … PASSWORD` con la contraseña en claro (línea 355 de `E5-rotados/postgresql-2026-11-07_211832.log`); hoy **incumple**.
- Registro de **lecturas** (`SELECT`) de datos sensibles: **hoy no existe** (`log_statement='mod'` no las registra; haría falta `pgaudit` o equivalente).

**Revisión:** semestral.
