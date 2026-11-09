# Evidencia 12 — Altas y bajas

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 13 — Altas y bajas
**Fecha:** 2026-11-07

## Comandos ejecutados

```sql
INSERT INTO clientes (nombre, correo, rfc, edad, ciudad, codigo_postal)
VALUES ('Pedro Ruiz', 'pedro.ruiz@example.test', 'RUPE950101AAA', 30, 'Guasave', '81000');
DELETE FROM clientes WHERE nombre = 'Pedro Ruiz';

SELECT id_evento, usuario_sesion, aplicacion, ip_cliente, operacion, id_cliente,
       valores_antes ->> 'rfc' AS rfc_antes, valores_despues ->> 'rfc' AS rfc_despues
FROM auditoria.cambios_clientes ORDER BY id_evento;
```

## Resultado obtenido

```
 id_evento | usuario_sesion |   aplicacion   | ip_cliente | operacion | id_cliente |   rfc_antes   |  rfc_despues
-----------+----------------+----------------+------------+-----------+------------+---------------+---------------
         1 | app_ventas     | app-ventas-web | 127.0.0.1  | UPDATE    |          3 | GAMA780912XYZ | GAMA780912ZZZ
         2 | postgres       | psql           | 127.0.0.1  | INSERT    |          6 |               | RUPE950101AAA
         3 | postgres       | psql           | 127.0.0.1  | DELETE    |          6 | RUPE950101AAA |
```

También en la bitácora: línea 510 (`INSERT INTO clientes …`) y 512 (`DELETE FROM clientes WHERE nombre = 'Pedro Ruiz';`), usuario `postgres`, aplicación `psql`, cliente `127.0.0.1`.

## Respuestas

1. **El cliente Pedro Ruiz ya no existe en `clientes`. ¿Dónde queda evidencia de que existió y de sus datos?**
   En `auditoria.cambios_clientes`: el evento 2 (INSERT) guarda la fila completa en `valores_despues` y el evento 3 (DELETE) la guarda en `valores_antes`. En la bitácora quedan las sentencias (líneas 510 y 512), pero solo con el texto que se escribió, no la fila completa.

2. **¿Por qué `ip_cliente` está vacía en los eventos 2 y 3?**
   En mi ejecución **no está vacía**: es `127.0.0.1`, porque la sesión de administrador se conectó por TCP. `inet_client_addr()` devuelve `NULL` cuando la conexión es por socket local, y eso explica el campo vacío que muestra la guía.

3. **La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?**
   Borrar a Pedro Ruiz de `clientes` no elimina sus datos personales: siguen completos en la auditoría, que además se conserva para evidencia. Chocan el principio de minimización/eliminación y la necesidad de conservar evidencia. Lo debe resolver el responsable de los datos junto con seguridad, auditoría y la persona responsable de privacidad o cumplimiento, definiendo plazos de conservación de la auditoría y qué se anonimiza o purga; no debe decidirlo el DBA por su cuenta.

## Interpretación

La auditoría conserva alta, baja y valores completos de un registro que ya no existe en la tabla. Eso es útil como evidencia y, a la vez, un riesgo de privacidad que debe gobernarse con una política de retención.
