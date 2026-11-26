# Evidencia 02 — Propietarios, custodios y usuarios

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 2 — Propietarios, custodios y usuarios (LAB-03)
**Fecha:** 2026-11-25

**Insumos.** Matriz de gobierno de datos de la Unidad II, Actividad 11 (`unidad-02/lab-03-privacidad-cumplimiento/evidencias/gobierno-datos.md`); privilegios vigentes (`E2-privilegios.txt`); roles del servidor (consulta de `pg_roles`); evidencias de LAB-01 y LAB-02.

## Cómo se combinan los dos niveles de responsabilidad

La Unidad II asignó un responsable por **campo** (RFC y código postal: Facturación; nombre, correo y teléfono: Atención al cliente; edad y ciudad: Analítica). La guía del LAB-03 y los `COMMENT` de `clientes` nombran a **Gerencia Comercial** como propietaria del **conjunto de datos**. Se concilian así:

- **Propietario del conjunto** (Gerencia Comercial): decide para qué se usa, quién accede y cuándo se elimina.
- **Responsable de campo** (matriz U2): decide si un valor de su campo es correcto y es quien aprueba la corrección.
- **Custodio** (DBA): opera y protege; no decide valores ni accesos.

## Matriz ampliada

| Conjunto de datos | Propietario | Custodio | Usuarios autorizados | Quién aprueba accesos | Quién aprueba correcciones |
|---|---|---|---|---|---|
| `comercial.public.clientes` (PostgreSQL) | Gerencia Comercial | DBA | Atención al cliente (nombre, correo, teléfono, ciudad); Facturación (nombre, RFC, código postal; correo solo para comprobantes); Analítica (edad en rangos, ciudad, vía vista); Dirección (solo agregados); DBA solo para mantenimiento o ARCO. Cuentas técnicas hoy: `app_ventas` (SELECT, UPDATE) y `soporte_ana` (SELECT) | Gerencia Comercial | Responsable de campo: RFC y código postal → Facturación; nombre, correo y teléfono → Atención al cliente; edad y ciudad → Analítica. Gerencia Comercial resuelve los conflictos |
| `auditoria.cambios_clientes` (PostgreSQL) | Auditoría interna | DBA (hoy); se recomienda seguridad de la información, ver H-09 | Auditoría interna (lectura). DBA solo administra la tabla; no la purga ni la modifica sin autorización | Auditoría interna | Ninguna: es evidencia y no se corrige. La depuración (POL-03) la autoriza Auditoría interna con el área jurídica |
| Bitácora de PostgreSQL (archivos de `log/`, vista `dba.bitacora`) | Auditoría interna | DBA | Auditoría interna (lectura). DBA con lectura controlada. Nadie más | Auditoría interna | Ninguna: no se edita. Se depura según POL-03 con acta |
| `gobierno.solicitudes_cambio` (PostgreSQL) | Comité de cambios | DBA | Comité de cambios (registro y aprobación), Auditoría interna (lectura), DBA (ejecuta dentro del folio) | Comité de cambios | Comité de cambios |
| `comercial.clientes` (MongoDB) | Gerencia Comercial (mismo propietario que en PostgreSQL, para evitar decisiones contradictorias) | DBA | `app_ventas` (aplicación `app-ventas-web`, visto en `system.profile`); el usuario administrador del DBA | Gerencia Comercial | Los mismos responsables de campo que en PostgreSQL |
| `comercial.system.profile` (MongoDB) | Auditoría interna | DBA | Auditoría interna (lectura); DBA | Auditoría interna | Ninguna: se exporta y se conserva según POL-03 |
| `auditoria.instantaneas_privilegios` (MongoDB) | Auditoría interna | DBA | Auditoría interna (lectura); DBA | Auditoría interna | Ninguna |

La cuenta `app_ventas` es una cuenta de aplicación. La matriz U2 no define un rol «ventas»; ver H-03 del expediente.

## Preguntas

**1. ¿Por qué el propietario de `auditoria.cambios_clientes` no debería ser el mismo que opera `clientes`?**
Porque quien opera los datos podría alterar su propia evidencia. El LAB-01 (Actividad 14) lo demostró: el administrador desactivó el disparador, cambió el RFC del cliente 3 y lo reactivó (líneas 531–533), y ese cambio no quedó en la tabla de auditoría. La separación de funciones exige que el dueño de la evidencia sea quien revisa, no quien opera.

**2. ¿Quién debería poder leer las bitácoras y la vista `dba.bitacora`? Relaciónalo con lo observado en el LAB-01.**
Solo Auditoría interna y, de forma controlada, el DBA. La bitácora contiene valores literales (RFC, teléfonos) y contenía una contraseña en texto claro (línea 355, `CREATE ROLE rol_temporal … PASSWORD`). Hoy `E2-privilegios.txt` no muestra ningún otorgamiento a roles distintos de `postgres` sobre `dba.bitacora` ni sobre `auditoria.*`: solo `postgres` puede leerlos. Cualquier extracción debe revisarse y redactarse antes de compartirse, como se hizo con E5.

**3. ¿Qué ocurre con la responsabilidad sobre un dato cuando nadie la tiene asignada? Relaciónalo con el problema inicial de la unidad.**
Nadie puede decir si un cambio fue indebido ni quién debe corregirlo. El problema inicial fue justamente ese: cambiaron el RFC de un cliente y Dirección no podía saber quién lo hizo, con qué valor anterior ni si estaba autorizado. Sin propietario tampoco hay quien apruebe accesos, acepte riesgos o decida las correcciones; los hallazgos de calidad (C1–C8) se quedarían sin atender.
