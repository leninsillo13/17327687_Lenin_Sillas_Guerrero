# Evidencia 03 — Diccionario de datos operativo

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 3 — Diccionario de datos operativo dentro del motor (LAB-03)
**Fecha:** 2026-11-21 (COMMENT aplicados 22:19 y reaplicados 22:29) · documento: 2026-11-25
**Archivos SQL:** `sql/02-comentarios-diccionario.sql` (más el `COMMENT` de `canal_alta` en `sql/04-registro-cambios.sql`)
**Salida:** `evidencias/diccionario-clientes.csv`

## Qué se hizo

Se documentaron con `COMMENT` la tabla `clientes` y sus 11 columnas. La consulta de columnas sin comentario devuelve **0 filas**. El CSV exportado contiene las 11 columnas, incluida `canal_alta` (agregada por el cambio CAM-2026-014).

Corrección registrada: el primer comentario de `fecha_alta` decía «fecha y hora» pero la columna es `date`. Se reaplicó el 2026-11-21 22:29:35 con el texto correcto. Ambas sentencias quedaron en la bitácora.

## Diccionario completado con lo que el motor no conoce

«Control aplicado» incluye **solo** lo que se pudo verificar en este servidor: `E2` (privilegios), `E3` (disparador) y la consulta de vistas (consulta de vistas de `sql/03`, que solo devuelve `dba.bitacora`). Los controles que la Unidad II propone y no se encontraron aquí se marcan como «no verificado».

| Columna | Tipo | Clasificación (U2) | Finalidad | Control aplicado (verificado) | ¿Cambios auditados? | Regla de calidad | Responsable de campo |
|---|---|---|---|---|---|---|---|
| `id` | bigint | Identificador interno, no personal | Llave del registro | Generado por secuencia; no editable por la aplicación | Sí | Único, no nulo | Gerencia Comercial |
| `nombre` | varchar(120) | Dato personal (identificador directo) | Atención y facturación | SELECT directo para `soporte_ana` y `app_ventas` | Sí | No nulo | Atención al cliente |
| `correo` | varchar(150) | Dato personal (sensibilidad alta) | Notificaciones y comprobantes | SELECT directo; sin enmascaramiento ni cifrado verificados | Sí | Formato de correo; único sin distinguir mayúsculas (C1, C4) | Atención al cliente |
| `telefono` | varchar(20) | Dato personal | Contacto operativo | SELECT directo; sin enmascaramiento verificado | Sí | 10 dígitos (C6) | Atención al cliente |
| `rfc` | varchar(13) | Dato personal (sensibilidad alta, fiscal) | Facturación | SELECT directo para `soporte_ana` (ve el RFC completo). **La vista enmascarada de la U2 no existe en esta base**; sin cifrado de columna | Sí (LAB-01 Parte B; fila completa en JSONB) | Formato de RFC de 13 caracteres (C2, C3) | Facturación |
| `edad` | integer | Dato personal | Analítica agregada | SELECT directo; la generalización en rangos de la U2 no se verificó | Sí | Rango 18–120 (C5) | Analítica |
| `ciudad` | varchar(80) | Dato personal (riesgo bajo; cuasi-identificador) | Logística y analítica | SELECT directo | Sí | Escritura normalizada (C8) | Analítica |
| `codigo_postal` | varchar(10) | Dato personal (cuasi-identificador) | Domicilio fiscal y entrega | SELECT directo | Sí | 5 dígitos (C7) | Facturación |
| `fecha_alta` | date | No personal | Control de altas | Valor por defecto `CURRENT_DATE` | Sí | No futura | Gerencia Comercial |
| `segmento` | varchar(20) | No clasificada en U2 (propuesta: dato de negocio derivado) | Analítica y campañas | SELECT directo | Sí | Valores de un catálogo (hoy el `UPDATE` masivo lo puso en `regular`) | Analítica (propuesto) |
| `canal_alta` | varchar(20) | No clasificada en U2 (propuesta: dato de negocio, no personal) | Canal de registro | Agregada por CAM-2026-014 | Sí, por diseño (el disparador guarda la fila completa). Aún no hay un evento posterior al cambio que lo demuestre | Valores de un catálogo (por definir) | Gerencia Comercial (propuesto) |

Las clasificaciones de `segmento` y `canal_alta` son propuestas mías: la Unidad II no las cubre, y deben confirmarlas Gerencia Comercial y el responsable de privacidad.

Observación: la matriz de la Unidad II exige que Atención al cliente **no** vea el RFC, la edad ni el código postal. Hoy `soporte_ana` tiene `SELECT` sobre toda la tabla (E2), así que ve esas columnas (hallazgo H-03).

## Preguntas

**1. ¿Qué ventaja tiene guardar el significado en `COMMENT` en lugar de solo en un documento aparte?**
El significado viaja con el objeto: cualquier herramienta lo consulta con `col_description`, aparece en `\d+`, se incluye en los respaldos de la base y no se desincroniza fácilmente cuando cambia la estructura (cada columna nueva se puede comentar en la misma transacción que la crea, como `canal_alta`). Un documento aparte envejece sin que nadie lo note y no está disponible para quien solo tiene acceso a la base.

**2. ¿Quedaron registrados los `COMMENT` en la bitácora? ¿Con qué nivel de `log_statement`?**
Sí. `COMMENT` es DDL: lo registran los niveles `ddl`, `mod` y `all`, y el servidor está en `mod` (E1). La consulta H9 de `sql/04` lista doce de ellos (se limitó a 12 filas), entre ellos los del 2026-11-21 22:29:35 (líneas 249–259 del archivo vigente) y el de `canal_alta` (línea 88). Se observa que los acentos de esas sentencias aparecen alterados («CÃ³digo»): la bitácora mezcla codificaciones (limitación L-06).

**3. ¿Qué información del diccionario debe mantenerse fuera del motor? ¿Por qué?**
Lo que el motor no puede garantizar ni debe exponer a cualquiera que lea el catálogo: las aprobaciones y su historial (quién decidió una clasificación o una corrección y cuándo), la base legal y los plazos de conservación, las aceptaciones de riesgo y las excepciones. Un `COMMENT` lo puede cambiar el propietario técnico de la tabla (`postgres`) sin más rastro que la bitácora, y no guarda versiones. Por eso el expediente y las políticas viven en el repositorio, con control de cambios.
