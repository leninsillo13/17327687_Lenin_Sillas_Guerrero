# Evidencia 05 — Criterio de conservación de bitácoras

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 5 — Criterio de conservación de bitácoras (LAB-03)
**Fecha:** 2026-11-25
**Base:** lo observado en LAB-01, LAB-02 y en consultas H0 y H7 de `sql/04`. Marco: NIST SP 800-92 (REF-U3-03).

## Lo observado que condiciona el criterio

- El colector escribe en `C:/Program Files/PostgreSQL/18/data/log`, **en el mismo equipo y disco que los datos**. Hay 15 archivos (dos vacíos), el más antiguo del 2026-10-17. Si se reinstala o recrea el servidor, la evidencia se pierde con él.
- El servidor registró **7 cierres inadecuados** («no fue apagado apropiadamente») entre el 2026-11-07 y el 2026-11-19 (H7). Entre el 2026-11-10 y el 2026-11-15 no hay actividad. La continuidad del registro no está garantizada.
- Antes de las ~21:33:52 del 2026-11-07 `log_statement` valía `none`: los archivos de octubre no contienen ninguna sentencia DDL (H1). Eso no se puede recuperar.
- La bitácora contenía una contraseña en texto claro (línea 355). Es un secreto: se trata con esa sensibilidad.
- MongoDB escribe su bitácora en la salida estándar del contenedor; `getLog` solo devuelve lo que está en memoria (LAB-02/evidencia 01). `system.profile` es una colección limitada que se sobrescribe sola.

## Criterio propuesto

Los periodos coinciden con los de POL-03. Son propuestas razonadas; ninguno es un plazo legal.

| Registro | Ubicación actual | Riesgo de pérdida observado | Sensibilidad | Periodo propuesto | Justificación | Dónde se conserva | Quién puede leerlo | Acción al vencer |
|---|---|---|---|---|---|---|---|---|
| Accesos de PostgreSQL | Archivos de `log/` (`pg_current_logfile()`) | Rotación; mismo disco que los datos; 7 cierres inadecuados | Media (usuarios, IP, aplicaciones) | **12 meses**. Plazo legal: a confirmar con el área jurídica | Cubre un ciclo anual de auditoría y la revisión trimestral (POL-01) | Copia exportada con hash en repositorio de custodia de Auditoría interna, fuera del servidor | Auditoría interna; DBA con lectura controlada | Eliminar con acta |
| Cambios de privilegios y estructura | Archivos de `log/` | Mismo riesgo; los de antes del 2026-11-07 no se registraron; contiene secretos | **Alta** | **24 meses**. Plazo legal: a confirmar | Pocos eventos, alto valor y necesarios para conciliar (POL-06) y revisar accesos; un cambio de hace un año puede explicar un incidente de hoy | Igual, más copia protegida; redactar secretos antes de exportar | Solo Auditoría interna | Eliminar con acta |
| Modificaciones de datos (`log_statement = 'mod'`) | Archivos de `log/` | Mismo riesgo; contiene valores literales; el nivel `ddl` no los registra (el UPDATE de 21:34:03 no quedó) | Alta (valores de clientes en claro) | **12 meses**. Plazo legal: a confirmar | Permite investigar cambios de datos; el volumen y los datos personales no justifican más | Igual, con acceso restringido | Solo Auditoría interna | Eliminar con acta |
| `auditoria.cambios_clientes` | Tabla en `comercial` | El administrador puede desactivar el disparador o vaciar la tabla (LAB-01/13); sin copia externa | Contiene datos personales completos | **24 meses** los metadatos; **12 meses** `valores_antes` y `valores_despues`, luego se vacían | Resuelve el conflicto de LAB-01 (Actividad 13): se conserva el evento, no el dato personal | Tabla protegida y respaldos cifrados (POL-02); exportación periódica con hash | Auditoría interna; el DBA solo administra | **Anonimizar** (vaciar los valores) y conservar los metadatos; al cumplirse los 24 meses eliminar con acta |
| Bitácora de `mongod` | Salida estándar del contenedor `dba-u3-mongo` | Se pierde si se recrea el contenedor (riesgo inherente al despliegue; no se probó en el laboratorio) | Media | **12 meses**. Plazo legal: a confirmar | Misma lógica que los accesos de PostgreSQL | Exportación periódica a archivo con hash (como `bitacora-mongod.log`) | Auditoría interna; DBA | Eliminar con acta |
| `system.profile` | Colección limitada de 1 MB | **Se sobrescribe sola**; sin exportar no hay historial | Alta (filtros y valores en claro, usuario e IP) | **6 meses** de lo exportado | Es evidencia parcial; guarda el valor nuevo pero no el anterior (LAB-02/evidencia 03) | Exportación a JSON con hash (`system-profile.json`) | Solo Auditoría interna | Eliminar con acta |
| Instantáneas de privilegios (MongoDB) | `auditoria.instantaneas_privilegios` | Están en el mismo servidor; el administrador puede borrarlas | Media | **24 meses**. Plazo legal: a confirmar | Son el único control compensatorio de cambios de privilegios en Community | Exportación periódica con hash | Auditoría interna; DBA | Eliminar con acta |

**Obligaciones a revisar con el área jurídica** (no se afirma ningún plazo): la normativa de protección de datos personales en posesión de particulares (conservación, bloqueo y supresión) y las obligaciones fiscales de conservación de la documentación relacionada con la facturación.

**Conflicto observado en LAB-01 (Actividad 13).** Eliminar a Pedro Ruiz de `clientes` no borra sus datos de la auditoría. El criterio lo resuelve con la anonimización a los 12 meses y la conservación del evento. La decisión final es de Auditoría interna, Gerencia Comercial y el área jurídica, no del DBA.

## Preguntas

**1. ¿Por qué la bitácora de cambios de privilegios merece más tiempo de conservación que la de consultas rutinarias?**
Por su valor y su volumen. Los cambios de privilegios son pocos y explican quién pudo hacer qué: se necesitan para la revisión trimestral de accesos, para conciliar con las solicitudes aprobadas y para investigar un incidente descubierto meses después. Las operaciones rutinarias son muchas, pesan más, rinden menos en una investigación y arrastran datos personales en claro que conviene no acumular.

**2. ¿Qué control de integridad aplicarás a las bitácoras exportadas?**
Un hash SHA-256 calculado al exportar (`E5-bitacora-postgresql.sha256`, `E5-rotados.sha256`, `hashes.sha256` de LAB-02), verificable con `sha256sum -c`. El hash debe guardarse **separado** del archivo y en manos de quien no lo produjo (Auditoría interna); si el mismo DBA puede cambiar archivo y hash, el control no prueba nada. Complementos: copia de solo lectura y un commit en un repositorio remoto como sello de fecha. Un límite que declaro: el hash prueba la integridad de **la copia exportada**, no la del archivo original del servidor (H-12).

**3. ¿Qué diferencia hay entre conservar una bitácora y respaldar una base de datos?**
La bitácora es evidencia de lo que ocurrió, se conserva sin modificar y no se restaura en el motor. El respaldo es una copia del estado de los datos para recuperarlos. Restaurar un respaldo no trae de vuelta las bitácoras posteriores a su fecha, y podría reintroducir datos que ya se habían eliminado por una solicitud de supresión. Tienen plazos, lectores y riesgos distintos. El mecanismo técnico del respaldo se define en la Unidad V; aquí solo se fija el criterio (POL-02, POL-03).
