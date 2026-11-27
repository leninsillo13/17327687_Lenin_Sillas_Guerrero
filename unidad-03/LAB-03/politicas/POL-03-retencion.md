# POL-03 — Retención

**Objetivo:** conservar la evidencia el tiempo suficiente para auditar e investigar, sin conservar datos personales más tiempo del necesario.

**Alcance:** bitácoras de PostgreSQL y de `mongod`, `auditoria.cambios_clientes`, `system.profile`, instantáneas de privilegios y los datos de `clientes` en ambos motores.

**Regla:**
1. Los periodos mínimos de conservación son los de la tabla siguiente (propuestos; los plazos que dependan de obligaciones legales son **plazo a confirmar con el área jurídica**, revisando al menos la normativa de protección de datos personales en posesión de particulares y las obligaciones fiscales sobre documentación de facturación).
2. Ninguna bitácora ni registro de auditoría se elimina antes de su periodo; al vencer, se elimina con acta firmada, salvo `auditoria.cambios_clientes`, cuyos valores se anonimizan y se conservan los metadatos.
3. Ante la eliminación de un cliente (o solicitud de supresión), se borran sus datos en `clientes`; en `auditoria.cambios_clientes` se vacían `valores_antes` y `valores_despues` y se conserva el evento (id, momento, usuario, operación, `id_cliente`). Como esa anonimización modifica evidencia, requiere un folio en `gobierno.solicitudes_cambio` autorizado por Auditoría interna, la ejecuta el DBA y queda registrada en la bitácora (`log_statement = 'mod'`).

| Registro | Periodo | Al vencer |
|---|---|---|
| Accesos de PostgreSQL | 12 meses | Eliminar con acta |
| Cambios de privilegios y estructura | 24 meses | Eliminar con acta |
| Modificaciones de datos (`log_statement='mod'`) | 12 meses | Eliminar con acta |
| `auditoria.cambios_clientes` (metadatos) | 24 meses | Eliminar con acta |
| `auditoria.cambios_clientes` (valores antes/después) | 12 meses | Anonimizar (vaciar valores) |
| Bitácora de `mongod` | 12 meses | Eliminar con acta |
| `system.profile` (exportado) | 6 meses | Eliminar con acta |
| Instantáneas de privilegios (MongoDB) | 24 meses | Eliminar con acta |
| Registro de cambios (`gobierno.solicitudes_cambio`) | 24 meses | Eliminar con acta |
| Datos de `clientes` | Plazo a confirmar con el área jurídica | Decide el propietario |

Coherencia: POL-05 necesita investigar incidentes con hasta 12 meses de accesos y modificaciones; por eso ninguna de esas bitácoras se elimina antes.

**Responsable:** decide el propietario del dato (Gerencia Comercial para `clientes`; Auditoría interna para bitácoras y auditoría); ejecuta el DBA; confirma plazos legales el área jurídica.

**Excepciones:** conservación ampliada por investigación o requerimiento de autoridad, autorizada por Auditoría interna y el área jurídica, con folio.

**Evidencia:** `evidencias/05-conservacion.md`, `evidencias/04-catalogo.md` (columna Conservación), hashes `evidencias/E5-bitacora-postgresql.sha256` e `INDICE-HASHES.txt`. Acta de eliminación de bitácoras vencidas: **hoy no existe** (aún no vence ninguna).

**Revisión:** anual, o cuando el área jurídica confirme un plazo.
