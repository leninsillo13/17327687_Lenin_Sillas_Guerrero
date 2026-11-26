# Evidencia 01 — Calidad de datos desde la operación

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 1 — Calidad de datos desde la operación (LAB-03)
**Fecha de ejecución:** 2026-11-21, 22:19 (hora local, UTC−6)
**Servidor:** PostgreSQL 18.6 en Windows, base `comercial`
**Archivo SQL:** `sql/01-verificaciones-calidad.sql`

## Qué se hizo

Se insertaron los dos registros con errores de la guía (ids **7** y **8**; `INSERT 0 1` ×2) y se ejecutaron las verificaciones. Se agregaron tres reglas que la guía no pide (teléfono, código postal y variantes de ciudad), porque el registro 8 las incumple. Los dos registros **no se eliminan ni se corrigen**: son hallazgos del expediente.

El disparador de auditoría registró las dos altas: eventos 9 y 10 de `auditoria.cambios_clientes`, usuario `postgres`, aplicación `psql`, 2026-11-21 22:19:56 (`E4-muestra-auditoria.txt`).

## Resultados

| Verificación | Resultado observado |
|---|---|
| Duplicados por `lower(correo)` | `ana.lopez@example.test`: 2 registros, ids 1 y 7 |
| RFC ausente o con formato no válido | id 7 (`LOAA850315AB`, 12 caracteres) e id 8 (`NULL`) |
| Correo con formato no válido | id 8 (`sin-correo`) |
| Edad fuera de 18–120 | id 8 (`-3`) |
| Teléfono distinto de 10 dígitos | id 8 (`667`) |
| Código postal distinto de 5 dígitos | id 8 (`8000`) |
| Ciudad con variantes de escritura | `Culiacan` / `Culiacán` |
| Completitud | total 7; sin teléfono 0; sin RFC 1 |

El id 7 no cumple el formato porque tiene 4 letras + 6 dígitos + 2 caracteres (12 en total). Un RFC de persona física lleva 3 caracteres de homoclave (13 en total). La expresión regular verifica solo el formato; no valida que el RFC exista ni sustituye las reglas del SAT.

## Hallazgos de calidad

| # | Hallazgo | Registros | Regla de calidad | ¿Quién decide la corrección? | Acción propuesta |
|---|---|---|---|---|---|
| C1 | Posible cliente duplicado | 1, 7 | Unicidad del correo (sin distinguir mayúsculas) | Atención al cliente (responsable de nombre y correo, matriz U2), con Gerencia Comercial como propietaria del conjunto | Determinar si es la misma persona; fusionar o corregir el correo. Sin esa decisión, no tocar |
| C2 | RFC incompleto | 7 | Formato del RFC (13 caracteres) | Facturación (responsable de `rfc`, matriz U2) | Solicitar el RFC completo al cliente o a su constancia fiscal |
| C3 | RFC ausente | 8 | RFC obligatorio para facturar | Facturación | Decidir si el cliente factura. Si sí, capturar; si no, documentar que no aplica |
| C4 | Correo con formato no válido | 8 | Formato de correo | Atención al cliente | Recapturar con el cliente |
| C5 | Edad fuera de rango (−3) | 8 | Rango 18–120 | Analítica (responsable de `edad`, matriz U2) | Corregir o vaciar el valor. No usar el registro en analítica mientras tanto |
| C6 | Teléfono con 3 dígitos | 8 | 10 dígitos | Atención al cliente | Recapturar |
| C7 | Código postal con 4 dígitos | 8 | 5 dígitos | Facturación (responsable de `codigo_postal`) | Recapturar |
| C8 | Misma ciudad escrita de dos formas | 7, 8 (y los demás con acento) | Escritura normalizada | Analítica (responsable de `ciudad`) | Definir una forma canónica y, mejor, un catálogo de ciudades |

El registro 8 acumula seis defectos (C3 a C8). Eso indica que la captura no valida nada en el origen.

**Escalamiento.** El DBA no corrige: avisa por escrito a Gerencia Comercial (propietaria del conjunto) con la lista de ids, la regla incumplida y el responsable de campo. El DBA ejecuta la corrección solo cuando el responsable la indica y exista folio en `gobierno.solicitudes_cambio` (POL-06).

## Preguntas

**1. ¿Por qué el DBA no debe corregir por su cuenta el RFC del registro 7?**
Porque el DBA es custodio, no propietario. No sabe cuál es el valor correcto: completar o inventar la homoclave produciría un RFC con apariencia válida pero falso, con efectos fiscales (facturas a un contribuyente equivocado). La corrección requiere una fuente (el cliente o su constancia fiscal) que solo el responsable del dato puede obtener. Además, un cambio de dato sin solicitud aprobada incumpliría POL-01 y POL-06 y dejaría al DBA como autor de una modificación que nadie autorizó, el mismo patrón del incidente del RFC de María García (LAB-01).

**2. ¿Qué restricción habría evitado cada hallazgo? ¿Quién debería aprobar agregarla?**

| Hallazgo | Restricción | Nota |
|---|---|---|
| C1 | `CREATE UNIQUE INDEX ... ON clientes (lower(correo))` | Un `UNIQUE (correo)` simple **no** lo habría evitado: `ANA.LOPEZ@…` y `ana.lopez@…` son cadenas distintas |
| C2 | `CHECK (rfc ~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$')` | Un CHECK acepta `NULL` |
| C3 | `NOT NULL` en `rfc` | Decisión de negocio: ¿todo cliente factura? |
| C4 | `CHECK (correo ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')` | |
| C5 | `CHECK (edad BETWEEN 18 AND 120)` | Acepta `NULL` |
| C6 | `CHECK (telefono ~ '^[0-9]{10}$')` | |
| C7 | `CHECK (codigo_postal ~ '^[0-9]{5}$')` | |
| C8 | Tabla de ciudades con llave foránea | Un CHECK simple no sirve |

Las aprobaría Gerencia Comercial como propietaria, previa opinión del responsable de cada campo (Facturación, Atención al cliente, Analítica), y se ejecutarían como cambio de producción con folio (POL-06). Como ya existen filas que las incumplen, habría que agregarlas con `NOT VALID` y validarlas (`VALIDATE CONSTRAINT`) una vez corregidos los datos.

**3. Si el DBA corrige un dato, ¿qué mecanismo del LAB-01 (Parte B) deja evidencia del cambio?**
El disparador `trg_auditoria_clientes` (E3, `tgenabled = O`) guarda en `auditoria.cambios_clientes` el usuario, la aplicación, la IP, la hora y la fila completa antes y después (JSONB). Además, `log_statement = 'mod'` deja la sentencia en la bitácora con usuario, aplicación y cliente. Límite: el administrador puede desactivar el disparador y el cambio quedaría solo en la bitácora (líneas 531–533 del archivo `postgresql-2026-11-07_211832.log`, LAB-01 Actividad 14).
