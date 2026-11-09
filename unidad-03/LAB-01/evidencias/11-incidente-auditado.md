# Evidencia 11 — Función, disparador e incidente auditado

**Estudiante:** Lenin Sillas Guerrero
**Actividades:** 11 (función y disparador) y 12 (el incidente auditado)
**Fecha:** 2026-11-07

> Esta evidencia reúne las Actividades 11 y 12, porque el disparador solo se puede validar con el incidente. El archivo de la Actividad 11 en la estructura de la guía es `sql/05-funcion-disparador.sql`.

## Comandos ejecutados

`sql/05-funcion-disparador.sql` (función `auditoria.registrar_cambio_cliente()` con `SECURITY DEFINER` y `SET search_path = pg_catalog, public`; `REVOKE ALL … FROM PUBLIC`; disparador `trg_auditoria_clientes` `AFTER INSERT OR UPDATE OR DELETE … FOR EACH ROW`).

Verificación:

```
         tgname         | tgenabled | tgrelid
------------------------+-----------+----------
 trg_auditoria_clientes | O         | clientes
```

`O` = habilitado. La bitácora registró la creación (líneas 434–436 esquema y tabla; 452 función; 475 `REVOKE ALL ON FUNCTION …`; 476 `CREATE TRIGGER`), porque `log_statement = mod` incluye DDL.

### Incidente (Actividad 12)

```
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3"      -> UPDATE 1
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial" -c "SELECT * FROM auditoria.cambios_clientes"                                                  -> ERROR:  permiso denegado al esquema auditoria
```

Como administrador:

```
-[ RECORD 1 ]----+------------------------------
id_evento        | 1
momento          | 2026-11-07 21:34:27.041262-06
usuario_sesion   | app_ventas
usuario_efectivo | postgres
aplicacion       | app-ventas-web
ip_cliente       | 127.0.0.1
operacion        | UPDATE
id_cliente       | 3
```

Campo modificado (`sql/06-campos-modificados.sql`):

```
 id_evento |            momento            | usuario_sesion | ip_cliente | campo |     antes     |    despues
-----------+-------------------------------+----------------+------------+-------+---------------+---------------
         1 | 2026-11-07 21:34:27.041262-06 | app_ventas     | 127.0.0.1  | rfc   | GAMA780912XYZ | GAMA780912ZZZ
```

La bitácora coincide: línea 491, `21:34:27.041 [19224] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG: sentencia: UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3;`. El intento de lectura de la auditoría quedó en las líneas 496–497 (`app=psql` porque ese intento no envió `application_name`).

## Respuestas

**Actividad 11**

1. **¿Por qué se ejecuta `REVOKE ALL ON FUNCTION … FROM PUBLIC` si el disparador seguirá funcionando para `app_ventas`?**
   Por defecto, `PUBLIC` tiene `EXECUTE` sobre las funciones nuevas; se retira para aplicar el mínimo privilegio (nadie salvo el propietario debe poder invocar una función `SECURITY DEFINER`). El disparador sigue funcionando porque PostgreSQL verifica el permiso `EXECUTE` sobre la función al crear el disparador, no cada vez que se dispara.

2. **¿Qué pasaría si la función no fuera `SECURITY DEFINER`?** *(hipótesis formulada antes de la Actividad 12, no probada en el servidor)*
   La función correría con los privilegios de `app_ventas`, que no tiene acceso al esquema `auditoria`; el `INSERT` fallaría con `permiso denegado` y, como el disparador es parte de la misma transacción, el `UPDATE` de la aplicación también se revertiría.

3. **Consulta `dba.bitacora`. ¿Quedó registrada la creación del esquema, la tabla, la función y el disparador? ¿Por qué?**
   Sí (líneas 434, 435, 436, 452, 475 y 476), porque `log_statement` era `mod`, que incluye todo lo de `ddl`. Las sentencias multilínea aparecen en varias líneas: solo la primera lleva prefijo.

**Actividad 12**

1. **Compara tu hipótesis de la Actividad 11 con este resultado.**
   Se confirma en parte: con `SECURITY DEFINER` el `UPDATE` de `app_ventas` funcionó y la auditoría se escribió aunque `app_ventas` no puede ni leerla. No probé la versión sin `SECURITY DEFINER`, así que el fallo hipotético sigue siendo una hipótesis.

2. **Escribe la sentencia `UPDATE` que restauraría el valor anterior.**

   ```sql
   UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3 AND rfc = 'GAMA780912ZZZ';
   ```
   Restaura el valor anterior **al cambio auditado** (XYZ). Con `AND rfc = …` no se pisa un cambio posterior. Ese valor tampoco es el original (`GAMA780912GHI`, que solo se conoce por el script de carga): XYZ ya era un cambio previo. La restauración quedaría auditada por el propio disparador.

3. **¿Qué columna conserva más valor para una investigación: `aplicacion` o `ip_cliente`? ¿Cuál puede falsificar el cliente con más facilidad?**
   `ip_cliente`: la fija la conexión TCP y no la declara el cliente (aunque NAT o un proxy puedan ocultar al origen real; aquí siempre es `127.0.0.1`). `aplicacion` (`application_name`) la declara el propio cliente en la cadena de conexión y cualquiera puede ponerle el valor que quiera.

## Interpretación

La auditoría permite demostrar quién cambió el RFC (`app_ventas`), cuándo, desde qué IP y aplicación, y el valor anterior (`XYZ`). `usuario_efectivo` es `postgres` porque dentro de una función `SECURITY DEFINER` `current_user` es el propietario; por eso la identidad de quien provocó el cambio es `session_user`. Hay que recordar que `app_ventas` es un rol compartido y no identifica a una persona.
