# Evidencia 07 — Modificaciones de datos: `ddl` frente a `mod`

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 7 — Modificaciones de datos
**Fecha:** 2026-11-07

## Comandos ejecutados

```
-- con log_statement = 'ddl'
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3"

ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();

-- con log_statement = 'mod'
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET telefono = '6679990000' WHERE id = 3" -c "SELECT nombre, rfc FROM clientes WHERE id = 3"
```

## Resultado obtenido

Con `ddl`: `UPDATE 1`. En la bitácora (ventana 21:34:03–21:34:10, extracto):

```
365 | 21:34:03.431 [19924] user=app_ventas ... client=127.0.0.1 LOG:  conexión autenticada: identidad=«app_ventas» ...
366 | 21:34:03.431 [19924] user=app_ventas ... LOG:  conexión autorizada: usuario=app_ventas base_de_datos=comercial nombre_de_aplicación=app-ventas-web ...
367 | 21:34:03.439 [19924] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  desconexión: duración de sesión: 0:00:00.051 ...
```

Aparecen la conexión y la desconexión de `app_ventas`, **pero no el UPDATE**.

Cambio de nivel y UPDATE con `mod`:

```
377 | 2026-11-07 21:34:06.664 CST [17912] user=postgres db=comercial app=psql client=127.0.0.1 LOG:  sentencia: ALTER SYSTEM SET log_statement = 'mod';
382 | 2026-11-07 21:34:09.796 CST [14304] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  sentencia: UPDATE clientes SET telefono = '6679990000' WHERE id = 3;
```

El `SELECT nombre, rfc …` (devolvió `María García | GAMA780912XYZ`) **no aparece**.

## Análisis

- Con `mod` aparecen quién (`app_ventas`), cuándo (21:34:09.796), desde dónde (`127.0.0.1`), con qué aplicación (`app-ventas-web`) y qué sentencia.
- La lectura del RFC no se registra: `mod` no incluye `SELECT`.
- La bitácora muestra lo que se escribió, pero no el teléfono anterior.
- El `ALTER SYSTEM` (línea 377) sí quedó registrado porque `log_statement` ya valía `ddl`. En este servidor, como se indicó en la evidencia 04, no aparece el mensaje `parameter … changed to …` de la recarga.

## Respuestas

1. **¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría en un servidor con miles de consultas por minuto?**
   `all`. Con miles de consultas por minuto, la bitácora crecería enormemente (escritura constante en disco, rotación frecuente, más almacenamiento y trabajo de lectura), podría degradar el rendimiento y, además, copiaría valores sensibles de todas las consultas al archivo de bitácora.

2. **¿Qué le falta a esta bitácora para revertir el cambio con certeza?**
   El valor anterior. La bitácora guarda la sentencia que se ejecutó (`telefono = '6679990000'`), pero no lo que tenía el teléfono antes ni el resultado exacto sobre cada fila. Se resuelve con la tabla de auditoría y el disparador de la Parte B.

## Interpretación

`log_statement = 'mod'` convierte un cambio de datos en evidencia atribuible (usuario, aplicación, IP y hora), pero solo hacia adelante: el `UPDATE` hecho con `ddl` no dejó rastro de la sentencia, y ninguno de los dos niveles conserva valores anteriores ni registra lecturas.
