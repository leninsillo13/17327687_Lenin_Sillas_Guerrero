# Evidencia 03 — El incidente sin bitácora

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 3 — El incidente sin bitácora
**Fecha:** 2026-11-07

## Comandos ejecutados

```sql
SHOW log_statement;   -- none
```

```
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3"
```

Búsqueda en la bitácora (ventana 21:33:46–21:33:49):

```sql
SELECT num, linea FROM dba.bitacora
WHERE substr(linea,1,19) BETWEEN '2026-11-07 21:33:46' AND '2026-11-07 21:33:49'
  AND (linea ILIKE '%update%' OR linea LIKE '%app_ventas%')
  AND linea NOT LIKE '%linea%'
ORDER BY num;
```

## Resultado obtenido

```
UPDATE 1

 num |                                       linea
-----+----------------------------------------------------------------------------------
 288 | 2026-11-07 21:33:46 CST LOG:  conexión autenticada: identidad=«app_ventas» método=scram-sha-256 (…/pg_hba.conf:149)
 289 | 2026-11-07 21:33:46 CST LOG:  conexión autorizada: usuario=app_ventas base_de_datos=comercial nombre_de_aplicación=app-ventas-web SSL habilitado (…)
 290 | 2026-11-07 21:33:46 CST LOG:  desconexión: duración de sesión: 0:00:00.050 usuario=app_ventas base=comercial host=127.0.0.1 port=50455
(3 filas)
```

(La primera ejecución de la búsqueda falló por el problema de codificación explicado en la evidencia 02; la consulta se repitió con la vista corregida.)

**Diferencia con la guía:** la guía dice que ni siquiera aparece la conexión de `app_ventas`. Aquí sí aparece, porque este servidor ya tenía `log_connections` activo. El `UPDATE`, en cambio, no aparece en ninguna línea.

## Respuestas

1. **¿Puedes demostrar quién modificó el RFC?**
   No. La bitácora muestra una sesión de `app_ventas` de 0.050 s a las 21:33:46 (líneas 288–290), pero no dice qué hizo. Que coincida en tiempo con el cambio es un indicio, no una prueba.

2. **¿Puedes demostrar que el cambio no lo hizo `soporte_ana`?**
   No con la bitácora: no registra sentencias de ningún rol. Lo único que lo hace improbable es el modelo de privilegios (`soporte_ana` solo tenía `SELECT`), pero eso dice qué *podía* hacer, no qué *hizo*; además `postgres` también podía hacerlo.

3. **Los privilegios de la Unidad II, ¿impidieron el cambio? ¿Debían impedirlo?**
   No lo impidieron, y no debían: `app_ventas` tiene `UPDATE` legítimo sobre `clientes`. El control de acceso responde «¿quién puede?», no «¿quién lo hizo y con qué valor anterior?».

4. **¿Qué tendría que haber estado configurado antes del incidente?**
   `log_statement` en `mod` (o superior), un `log_line_prefix` con `%u %d %a %h` (y PID y milisegundos) y, para el valor anterior, una tabla de auditoría con disparador (Parte B).

## Interpretación

El cambio ocurrió y no quedó registro de él. Lo que no se configuró antes del incidente no puede reconstruirse después: el RFC original solo se conoce por el script de carga (`GAMA780912GHI`), no por ninguna evidencia del servidor.
