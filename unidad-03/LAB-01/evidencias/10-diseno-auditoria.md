# Evidencia 10 — Diseño del registro de auditoría

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 10 — Diseñar y crear el registro de auditoría
**Fecha:** 2026-11-07

## Diseño de campos

| Campo | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
|---|---|---|---|
| id_evento | BIGSERIAL | Identifica y ordena cada evento (permite citarlo y detectar huecos en la secuencia) | No: llave primaria |
| momento | TIMESTAMPTZ | ¿Cuándo? | No: todo evento tiene hora (`DEFAULT now()`) |
| usuario_sesion | TEXT | ¿Quién lo hizo? (rol con que se autenticó) | No: siempre hay un rol de sesión (`DEFAULT session_user`) |
| usuario_efectivo | TEXT | ¿Con qué privilegios se ejecutó? (en la función `SECURITY DEFINER` es el propietario) | No (`DEFAULT current_user`) |
| aplicacion | TEXT | ¿Desde qué aplicación? | Sí: el cliente puede no declarar `application_name` |
| ip_cliente | INET | ¿Desde qué equipo? | Sí: es `NULL` si la conexión es por socket local |
| operacion | TEXT | ¿Qué ocurrió? (INSERT, UPDATE o DELETE) | No |
| id_cliente | BIGINT | ¿A qué registro afectó? | Sí en el diseño (podría haber eventos sin una fila concreta, p. ej. TRUNCATE); aquí siempre se llena |
| valores_antes | JSONB | ¿Qué valor tenía antes? | Sí: es `NULL` en un INSERT |
| valores_despues | JSONB | ¿Qué valor tiene ahora? | Sí: es `NULL` en un DELETE |

## Comandos ejecutados

Ver `sql/04-esquema-auditoria.sql`:

```
CREATE SCHEMA
REVOKE
CREATE TABLE
```

Bitácora (`log_statement = mod`), líneas 434–436: el servidor registró `CREATE SCHEMA auditoria;`, `REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;` y `CREATE TABLE auditoria.cambios_clientes (…` (usuario `postgres`, aplicación `psql`, cliente `127.0.0.1`).

## Respuestas

1. **¿Por qué `momento` usa `TIMESTAMPTZ` y no `TIMESTAMP`?**
   `TIMESTAMPTZ` guarda un instante absoluto (se almacena normalizado) y lo muestra en la zona de la sesión (`-06` en mis resultados). `TIMESTAMP` sin zona no dice a qué zona pertenece y, al comparar contra la bitácora (`CST`) o sistemas en UTC, el desfase se vuelve una conjetura.

2. **¿Por qué se guarda el registro completo en JSONB y no solo la columna que cambió?**
   Para conservar el estado completo de la fila antes y después: se pueden reconstruir y restaurar valores, y sirve para columnas que se añadan después (la tabla `clientes` ya cambió con `segmento`). La comparación campo por campo se hace al consultar (Actividad 12). El costo es más espacio y que la auditoría contiene todos los datos personales de la fila.

3. **La tabla de auditoría también contendrá RFC. ¿Qué implica eso para su clasificación y su control de acceso?**
   Que tiene al menos la misma clasificación que `clientes` (datos personales) y, de hecho, más exposición: guarda el historial, incluso de filas borradas. Debe tener acceso restringido (por eso el esquema `auditoria` se creó sin acceso para `PUBLIC` y `app_ventas` no puede leerlo), formar parte de los respaldos protegidos y tener una política de retención definida.

## Interpretación

Cada campo responde una pregunta de Dirección (quién, cuándo, desde dónde, qué valor tenía). Los campos de contexto (`session_user`, `current_setting('application_name')`, `inet_client_addr()`) se capturan por defecto al insertar, por lo que no dependen de la aplicación.
