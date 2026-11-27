# POL-02 — Respaldo

**Objetivo:** reducir el riesgo de perder datos de la base comercial por falla, error humano o incidente.

**Alcance:** base `comercial` de PostgreSQL (esquemas `public`, `auditoria`, `gobierno`, `dba`), base `comercial` de MongoDB (incluida `auditoria.instantaneas_privilegios`) y los archivos de configuración del registro de eventos. Producción obligatoria; pruebas y desarrollo según decida el propietario.

**Regla:**
1. Se respalda diariamente la base de producción completa de ambos motores y, semanalmente, las bitácoras exportadas junto con su hash SHA-256 (frecuencias propuestas, sujetas a aprobación del propietario).
2. Un respaldo solo cuenta como válido después de una prueba de restauración en un ambiente distinto a producción, hecha al menos cada trimestre y verificada por una persona distinta de quien ejecuta el respaldo.
3. El respaldo no sustituye la conservación de bitácoras: estas se rigen por POL-03.

**Responsable:** decide el propietario del dato (Gerencia Comercial); ejecuta el DBA; verifica Auditoría interna o quien designe el propietario.

**Excepciones:** omitir un respaldo por mantenimiento, solo con folio en `gobierno.solicitudes_cambio` aprobado por el propietario y con fecha de reposición.

**Evidencia:** hoy **no existe** un registro de respaldos ni de pruebas de restauración (se definirá con el procedimiento técnico en la Unidad V). Hasta entonces el cumplimiento de esta política no es demostrable y se reporta como hallazgo en `EXPEDIENTE.md`.

**Procedimiento técnico:** El procedimiento técnico se definirá en la Unidad V.

**Revisión:** anual, y tras cualquier incidente de pérdida de datos.
