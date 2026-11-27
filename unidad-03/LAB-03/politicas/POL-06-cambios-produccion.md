# POL-06 — Cambios en producción

**Objetivo:** que todo cambio en producción esté autorizado, ocurra dentro de una ventana y deje evidencia, sin desactivar los controles de auditoría.

**Alcance:** cambios de estructura (`CREATE/ALTER/DROP`), privilegios (`GRANT/REVOKE`), parámetros de registro, disparadores y restauraciones en la base `comercial`, en el ambiente de producción.

**Ambiente:** definición de trabajo adoptada en este expediente, porque la definición de la Unidad I no estaba disponible: *ambiente* es el conjunto de servidor, base de datos, cuentas y datos que se usa con un propósito y un nivel de riesgo determinados. Se distinguen *desarrollo* (pruebas del equipo, con datos ficticios), *pruebas* (validación previa a producción) y *producción* (el ambiente que atiende la operación y contiene los datos reales de clientes). Estos tres valores coinciden con los que admite `gobierno.solicitudes_cambio`. En esta práctica, la base `comercial` del servidor DESKTOP-R2B8AMH se trata como producción simulada, y esta política aplica a `produccion`. No hay separación física de ambientes (hallazgo H-19).

**Regla:**
1. **Antes:** existe un folio en `gobierno.solicitudes_cambio` con descripción, solicitante, aprobador distinto del solicitante, ambiente y ventana; el cambio se probó antes en pruebas.
2. **Durante:** el DBA ejecuta solo dentro de la ventana aprobada y no desactiva `trg_auditoria_clientes` ni cambia `log_statement` salvo que el folio lo autorice de forma explícita; si se desactiva, se reactiva dentro de la misma ventana.
3. **Después:** el DBA verifica el estado del disparador (consulta de E3), actualiza el `COMMENT` del objeto y una persona distinta del ejecutor concilia mensualmente la bitácora contra los folios.

**Responsable:** aprueba el Comité de cambios (con el propietario del dato si afecta datos); ejecuta el DBA; concilia Auditoría interna.

**Excepciones:** cambio de emergencia ante un incidente, autorizado por el propietario del dato y regularizado con folio en un máximo de 1 día hábil.

**Evidencia:** tabla `gobierno.solicitudes_cambio`; líneas `sentencia: CREATE/ALTER/DROP/GRANT/REVOKE` (en un servidor en inglés, `statement:`) en `evidencias/E5-rotados/` y `evidencias/E5-bitacora-postgresql.log` (por ejemplo, L87 de este último para CAM-2026-014); `evidencias/06-conciliacion.md`; `evidencias/E3-disparadores.txt`.

**Revisión:** semestral.
