# POL-01 — Acceso

**Objetivo:** reducir el riesgo de que alguien acceda a `clientes` o a las bitácoras sin autorización o con más privilegios de los necesarios.

**Alcance:** PostgreSQL 16 (`public.clientes`, `auditoria.*`, `gobierno.*`, `dba.bitacora`, archivos de bitácora) y MongoDB 7 (`comercial.clientes`, `system.profile`, `auditoria.instantaneas_privilegios`). Ambientes de desarrollo, pruebas y producción.

**Regla:**
1. Todo acceso nuevo o cambio de privilegios en producción requiere una solicitud registrada en `gobierno.solicitudes_cambio`, aprobada por el propietario del dato (Gerencia Comercial para `clientes`; Auditoría interna para bitácoras y auditoría) y con privilegios mínimos (si basta `SELECT`, no se otorga `UPDATE`).
2. Las cuentas temporales se crean con fecha de vencimiento (`VALID UNTIL`) y no se escriben contraseñas en sentencias SQL.
3. Cada trimestre el DBA compara los privilegios vigentes (consulta de E2) contra las solicitudes aprobadas y levanta un acta firmada por el propietario.

**Responsable:** decide el propietario del dato; ejecuta el DBA (custodio); revisa Auditoría interna.

**Excepciones:** acceso de emergencia durante un incidente, concedido por el DBA con autorización del propietario (aunque sea verbal) y regularizado con folio en un máximo de 1 día hábil. Autoriza: propietario del dato.

**Evidencia:**
- Líneas `sentencia: GRANT/REVOKE/CREATE ROLE` (en un servidor en inglés, `statement:`) en `evidencias/E5-rotados/postgresql-2026-11-07_211832.log` (L348, L349, L355) y, para el archivo vigente, en `evidencias/E5-bitacora-postgresql.log`.
- `evidencias/E2-privilegios.txt` (privilegios vigentes).
- Tabla `gobierno.solicitudes_cambio` y `evidencias/06-conciliacion.md`.
- Acta trimestral de revisión de accesos: **hoy no existe** (se creará con la primera revisión).

**Revisión:** semestral, o antes si cambia el propietario de algún dato.
