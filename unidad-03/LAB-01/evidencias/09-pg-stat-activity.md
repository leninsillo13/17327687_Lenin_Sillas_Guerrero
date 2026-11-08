# Evidencia 09 — Sesiones activas con `pg_stat_activity`

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 9 — Sesiones activas con pg_stat_activity
**Fecha:** 2026-11-07

## Comandos ejecutados

Reporte simulado (**30 s en vez de 90 s**, solo cambia la duración):

```
psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial?application_name=reporte-mensual" -c "SELECT pg_sleep(30)"
```

```sql
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';

SELECT num, linea FROM dba.bitacora WHERE linea LIKE '%[16124]%' ORDER BY num;
```

## Resultado obtenido

Mientras corre el reporte (21:56:26):

```
  pid  |   usename   | application_name | client_addr |         backend_start         | state  |             query
-------+-------------+------------------+-------------+-------------------------------+--------+--------------------------------
 15912 | postgres    | psql             | 127.0.0.1   | 2026-11-07 21:56:26.767686-06 | active | SELECT pid, usename, applicati
 16124 | soporte_ana | reporte-mensual  | 127.0.0.1   | 2026-11-07 21:56:21.771372-06 | active | SELECT pg_sleep(30)
```

Después de que termina (21:56:54): solo queda la sesión del propio administrador (PID 18944); la de `soporte_ana` ya no existe.

Líneas de bitácora del PID 16124:

```
661 | 2026-11-07 21:56:21.789 CST [16124] user=[desconocido] ... client=127.0.0.1 LOG:  conexión recibida: host=127.0.0.1 port=50546
662 | 2026-11-07 21:56:21.813 CST [16124] user=soporte_ana ... LOG:  conexión autenticada: identidad=«soporte_ana» método=scram-sha-256 (…/pg_hba.conf:149)
663 | 2026-11-07 21:56:21.813 CST [16124] user=soporte_ana ... LOG:  conexión autorizada: usuario=soporte_ana base_de_datos=comercial nombre_de_aplicación=reporte-mensual SSL habilitado (protocolo=TLSv1.3, …)
672 | 2026-11-07 21:56:51.857 CST [16124] user=soporte_ana db=comercial app=reporte-mensual client=127.0.0.1 LOG:  desconexión: duración de sesión: 0:00:30.086 usuario=soporte_ana base=comercial host=127.0.0.1 port=50546
```

(La actividad se ejecutó antes a las 21:34 y 21:49 en la serie automática; la evidencia mostrada es la repetición de las 21:56, con la vista corregida.)

## Respuestas

1. **¿Qué columna permite relacionar una sesión con sus líneas de bitácora?**
   `pid` de `pg_stat_activity`, que coincide con el número entre corchetes del prefijo (`%p`).

2. **Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?**
   La bitácora: las líneas 661–663 y la 672 (con `session time 0:00:30.086`, usuario, aplicación y cliente). `pg_stat_activity` es una fotografía del momento y ya no muestra la sesión.

3. **¿Por qué `client_addr` aparece vacío en la sesión del administrador?**
   En mi ejecución **no apareció vacío**: muestra `127.0.0.1`, porque mi sesión de administrador se conectó por TCP (regla `host`, línea 147 de `pg_hba.conf`). Aparece vacío cuando la conexión es por socket local (en ese caso `client_addr` es `NULL`), que es lo que muestra la guía.

## Interpretación

`pg_stat_activity` responde qué ocurre ahora (quién está conectado, desde qué aplicación y qué ejecuta); la bitácora responde qué ocurrió. Una sesión terminada desaparece de la vista pero deja su historia en la bitácora, y el PID es la llave para unirlas.
