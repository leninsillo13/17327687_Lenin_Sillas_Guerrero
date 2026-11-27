# POL-04 — Restauración

**Objetivo:** evitar que una restauración sobrescriba datos válidos, borre evidencia o deje la base sin controles de auditoría.

**Alcance:** restauración total o parcial de la base `comercial` de PostgreSQL y de MongoDB, en cualquier ambiente (en producción aplican todas las reglas).

**Regla:**
1. Toda restauración en producción requiere un folio aprobado en `gobierno.solicitudes_cambio` por el propietario del dato y por el Comité de cambios, y se ejecuta dentro de la ventana aprobada.
2. Antes de restaurar, el DBA guarda una copia del estado actual y de las bitácoras vigentes; las bitácoras nunca se sobrescriben con la restauración.
3. Después de restaurar, el DBA verifica que el disparador de auditoría siga habilitado (consulta de E3) y que los privilegios coincidan con los aprobados (consulta de E2), y una persona distinta valida los datos.

**Responsable:** autoriza el propietario del dato y el Comité de cambios; ejecuta el DBA; valida Auditoría interna o quien designe el propietario.

**Excepciones:** restauración urgente por caída de producción, ordenada por el propietario y regularizada con folio en un máximo de 1 día hábil.

**Evidencia:** folio en `gobierno.solicitudes_cambio`; `E3-disparadores.txt` y `E2-privilegios.txt` tomados después de la restauración; líneas de la bitácora (`E5-bitacora-postgresql.log`). Acta de restauración: **hoy no existe** (no se ha practicado ninguna).

**Procedimiento técnico:** El procedimiento técnico se definirá en la Unidad V.

**Revisión:** anual, y tras cada restauración real.
