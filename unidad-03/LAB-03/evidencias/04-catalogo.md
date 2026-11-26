# Evidencia 04 — Catálogo mínimo de datos

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 4 — Catálogo mínimo de datos (LAB-03)
**Fecha:** 2026-11-21 (inventario) · documento: 2026-11-25
**Archivo SQL:** `sql/03-inventario-tablas.sql`

## Inventario técnico obtenido del motor

| Esquema | Objeto | Tipo | Propietario técnico | Filas estimadas | Tamaño | Descripción (`COMMENT`) |
|---|---|---|---|---|---|---|
| `public` | `clientes` | tabla | `postgres` | 7 | 24 kB | Sí |
| `auditoria` | `cambios_clientes` | tabla | `postgres` | 10 | 32 kB | **No tiene** |
| `gobierno` | `solicitudes_cambio` | tabla | `postgres` | 1 | 32 kB | Sí |
| `dba` | `bitacora` | **vista** | `postgres` | — | — | **No tiene** |

Esquemas: `auditoria`, `dba`, `gobierno` (propietario `postgres`) y `public` (`pg_database_owner`). La vista `dba.bitacora` no aparece en la consulta de tablas (`relkind = 'r'`); se encontró con la consulta de vistas incluida en `sql/03`. Es la única vista de la base: no existe la vista enmascarada para soporte que propone la Unidad II (H-03).

El propietario técnico de todo es `postgres`. Eso es el dueño del objeto en el motor, no el propietario del dato en la organización.

Pendiente recomendado (no ejecutado, porque sería un cambio de producción que requiere folio): agregar `COMMENT` a `auditoria.cambios_clientes` y a `dba.bitacora`.

## Catálogo

Servidores: PostgreSQL 18.6 en `localhost:5432` (Windows, equipo `DESKTOP-R2B8AMH`); MongoDB 7.0.48 Community en `localhost:27017` (contenedor Docker `dba-u3-mongo`, imagen `mongo:7`).

| ID | Conjunto de datos | Motor | Ubicación | Propietario | Custodio | Clasificación | Datos personales | Finalidad | Conservación | Diccionario |
|---|---|---|---|---|---|---|---|---|---|---|
| CAT-01 | Clientes | PostgreSQL 18.6 | `localhost:5432` / comercial / `public.clientes` | Gerencia Comercial | DBA | Confidencial | Sí | Atención, facturación y analítica de clientes | Relación comercial más plazo fiscal; plazo a confirmar con el área jurídica (POL-03) | `diccionario-clientes.csv` |
| CAT-02 | Auditoría de clientes | PostgreSQL 18.6 | `localhost:5432` / comercial / `auditoria.cambios_clientes` | Auditoría interna | DBA | Confidencial | Sí: guarda la fila completa antes y después (RFC, correo, etc.), también de clientes ya eliminados | Trazabilidad de cambios en `clientes` | 24 meses los metadatos; 12 meses los valores, luego se anonimizan (POL-03) | Campos descritos en LAB-01/evidencia 10 |
| CAT-03 | Registro de cambios | PostgreSQL 18.6 | `localhost:5432` / comercial / `gobierno.solicitudes_cambio` | Comité de cambios | DBA | Interno | No (solo áreas y roles; podría tenerlos si se capturan nombres de personas) | Evidencia de POL-06 | 24 meses (propuesto) | Ver `sql/04-registro-cambios.sql` |
| CAT-04 | Clientes (tienda) | MongoDB 7.0.48 | `localhost:27017` / comercial / `clientes` | Gerencia Comercial | DBA | Confidencial | Sí | Clientes de la tienda | Igual que CAT-01 (POL-03) | Sin diccionario formal. **Pendiente**: describir sus campos |
| CAT-05 | Perfilado | MongoDB 7.0.48 | `localhost:27017` / comercial / `system.profile` | Auditoría interna | DBA | Confidencial | Sí: filtros y valores en claro (por ejemplo el RFC de un `update`), usuario y dirección del cliente | Trazabilidad parcial de operaciones | 6 meses lo exportado; la colección vigente se sobrescribe sola | Estructura vista en LAB-02/evidencia 03 |
| CAT-06 | Bitácora de PostgreSQL | PostgreSQL 18.6 | `localhost:5432` / archivos `log/` del directorio de datos y vista `dba.bitacora` | Auditoría interna | DBA | Confidencial | Sí: literales de sentencias; contenía una contraseña (línea 355) | Auditoría de accesos, cambios y errores | 12 meses accesos y modificaciones; 24 meses privilegios y estructura (POL-03) | Formato en LAB-01/evidencia 05 |
| CAT-07 | Bitácora de `mongod` | MongoDB 7.0.48 | `localhost:27017` / salida estándar del contenedor (`docker logs dba-u3-mongo`) | Auditoría interna | DBA | Confidencial | Sí: usuarios y direcciones IP | Accesos y cambios de configuración del perfilador | 12 meses (POL-03) | — |
| CAT-08 | Instantáneas de privilegios | MongoDB 7.0.48 | `localhost:27017` / `auditoria.instantaneas_privilegios` (según la guía; confirmar la ubicación exacta en LAB-02/evidencia 07) | Auditoría interna | DBA | Confidencial | No (roles y privilegios; contiene nombres de cuentas) | Control compensatorio de cambios de privilegios | 24 meses (POL-03) | — |

Cumple el mínimo: **8 conjuntos en los dos motores** (la verificación pide al menos cinco).

## Preguntas

**1. ¿Por qué CAT-02 y CAT-05 contienen datos personales aunque su propósito sea la auditoría?**
Porque la evidencia reproduce el dato. `auditoria.cambios_clientes` guarda la fila completa en `valores_antes` y `valores_despues` (RFC, correo, teléfono), incluso de clientes eliminados: el cliente Pedro Ruiz ya no está en `clientes` y sus datos siguen completos en los eventos 2 y 3. `system.profile` guarda el filtro y el valor nuevo de cada operación (el `update` del RFC del `_id: 3`), más el usuario y la IP. Por eso heredan la clasificación de `clientes` y necesitan acceso restringido y plazo de conservación (POL-03, POL-05).

**2. ¿Qué pasa si CAT-01 y CAT-04 tienen propietarios distintos y el RFC de un cliente difiere entre ambos motores?**
Nadie tiene autoridad para decir cuál es correcto, y cada propietario puede corregir el suyo sin avisar al otro; la divergencia se vuelve permanente. Por eso se asignó el mismo propietario a ambos conjuntos y el RFC lo resuelve Facturación. Hay un indicio real: PostgreSQL deja el RFC del cliente 3 con sufijo `GHI` (línea 532) y el `update` de MongoDB (`system.profile`, 2026-11-15) lo fija con sufijo `XYZ`. No verificado: que el `_id: 3` de MongoDB sea el mismo cliente. Si lo es, las dos bases ya divergen.

**3. ¿Qué información del catálogo cambia con más frecuencia y quién debe actualizarla?**
Lo técnico: filas, tamaño y la aparición de objetos nuevos (el esquema `gobierno` y la columna `canal_alta` nacieron el 2026-11-21). Lo actualiza el DBA como custodio, y puede automatizarse con la consulta de `sql/03`. También cambian los usuarios autorizados y, con menos frecuencia, la clasificación, finalidad y conservación; esas las decide y las actualiza el propietario, y Auditoría interna las revisa.
