# Evidencia 05 — Accesos exitosos y fallidos

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 5 — Accesos exitosos y fallidos
**Fecha:** 2026-11-07

## Comandos ejecutados

```
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial" -c "SELECT 1"              (contraseña incorrecta)
psql "postgresql://usuario_inexistente:<REDACTED>@127.0.0.1/comercial" -c "SELECT 1"
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "SELECT count(*) FROM clientes"
```

## Resultado obtenido

Cliente: dos errores `FATAL: la autentificación password falló para el usuario «…»` (idénticos para el usuario existente y el inexistente) y `count = 5` en el tercer intento.

Bitácora, ventana 21:33:56–21:33:58, filtro `client=127.0.0.1` (21 filas; extracto sin el ruido de la sesión del administrador):

```
312 ... [12928] user=[desconocido] ... client=127.0.0.1 LOG:  conexión recibida: host=127.0.0.1 port=50460
313 ... [12928] user=app_ventas db=comercial app=[desconocido] client=127.0.0.1 FATAL:  la autentificación password falló para el usuario «app_ventas»
314 ... [12928] user=app_ventas ... DETALLE:  La conexión coincidió con el archivo «…/pg_hba.conf» línea 149: «host comercial app_ventas,soporte_ana 127.0.0.1/32 scram-sha-256»
315-317 (segunda conexión, PID 19392, mismo resultado)
318 ... [14384] user=[desconocido] ... conexión recibida: host=127.0.0.1 port=50462
319 ... [14384] user=usuario_inexistente db=comercial app=[desconocido] client=127.0.0.1 FATAL:  la autentificación password falló para el usuario «usuario_inexistente»
320 ... [14384] user=usuario_inexistente ... DETALLE:  No existe el rol «usuario_inexistente».
322-324 (segunda conexión, PID 11424, mismo resultado)
326 ... [5232] ... conexión recibida: host=127.0.0.1 port=50464
327 ... [5232] user=app_ventas ... LOG:  conexión autenticada: identidad=«app_ventas» método=scram-sha-256 (…/pg_hba.conf:149)
328 ... [5232] user=app_ventas db=comercial app=[desconocido] client=127.0.0.1 LOG:  conexión autorizada: usuario=app_ventas base_de_datos=comercial nombre_de_aplicación=app-ventas-web SSL habilitado (protocolo=TLSv1.3, …)
329 ... [5232] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  desconexión: duración de sesión: 0:00:00.048 …
```

Cada intento fallido deja **dos** líneas `FATAL` (dos conexiones, puertos distintos). Es probable que sea el cliente reintentando con y sin SSL, pero la bitácora no lo dice.

Conteo de intentos fallidos por usuario (sin filtrar las líneas de continuación de consultas anteriores, que salen con usuario vacío):

```
       usuario       | intentos_fallidos
---------------------+-------------------
                     |                 4      <- líneas de continuación de sentencias registradas, no son accesos
 app_ventas          |                 2
 usuario_inexistente |                 2
```

### Lectura campo por campo (línea 313)

| Campo | Valor | Significado |
|---|---|---|
| Fecha y hora | 2026-11-07 21:33:56.224 CST | Con milisegundos, zona America/Mexico_City (UTC−6) |
| PID | 12928 | Proceso de esa conexión; une todas sus líneas |
| Usuario | app_ventas | Rol que el cliente *dijo* ser |
| Base de datos | comercial | Base solicitada |
| Aplicación | [desconocido] | Aún no se conocía el `application_name` (y en este intento no se envió) |
| Cliente | 127.0.0.1 | Dirección de origen de la conexión TCP |
| Severidad | FATAL | Termina la sesión |
| Mensaje | la autentificación password falló | Autenticación rechazada |
| Regla aplicada | pg_hba.conf línea 149 | `host comercial app_ventas,soporte_ana 127.0.0.1/32 scram-sha-256` |

## Respuestas

1. **La bitácora registra el usuario `app_ventas` en el intento fallido. ¿Eso prueba que la aplicación de ventas intentó entrar? ¿Qué prueba realmente?**
   No lo prueba. Prueba que alguien, desde `127.0.0.1` a las 21:33:56.224, presentó el nombre de rol `app_ventas` con una contraseña incorrecta. Cualquier persona o proceso que conozca el nombre puede decir que es ese usuario: la bitácora registra el rol declarado, no a la persona ni a la aplicación.

2. **¿Qué información adicional registra PostgreSQL cuando el rol no existe? ¿Por qué aparece en la bitácora y no en el mensaje que recibe el cliente?**
   Registra `DETALLE: No existe el rol «usuario_inexistente»` (línea 320). El cliente recibe el mismo mensaje genérico que con una contraseña incorrecta, para no revelar qué usuarios existen (enumeración de usuarios). El administrador sí necesita el detalle para investigar.

3. **¿Por qué `app=[desconocido]` en el intento fallido, pero `app=app-ventas-web` en la desconexión?**
   Durante la autenticación la sesión todavía no tiene aplicada su `application_name` (se aplica al completarse la conexión), y en los intentos fallidos además no se envió ninguno. En la desconexión (línea 329) la sesión ya existía y `%a` ya lo conoce. Ocurre incluso en la línea 328, cuyo prefijo dice `[desconocido]` pero cuyo mensaje sí dice `nombre_de_aplicación=app-ventas-web`.

4. **¿Qué patrón de varias líneas te haría sospechar de un ataque de fuerza bruta? Escribe la consulta que contaría los intentos fallidos por usuario.**
   Muchos `FATAL` de autenticación en poco tiempo desde el mismo `client=` (o desde pocos clientes contra muchos usuarios, o contra un solo usuario), especialmente si terminan con un acceso exitoso. Consulta propuesta, adaptada al servidor en español (no la ejecuté con un umbral porque aquí solo hay 2 intentos por usuario):

   ```sql
   SELECT substring(linea from 'user=([^ ]+) ')   AS usuario,
          substring(linea from 'client=([^ ]+) ') AS cliente,
          count(*)                                AS intentos_fallidos,
          min(substr(linea, 1, 23))               AS primero,
          max(substr(linea, 1, 23))               AS ultimo
   FROM dba.bitacora
   WHERE linea ~ 'FATAL:  la autentificaci.n password fall'
     AND linea ~ ' user='
   GROUP BY 1, 2
   HAVING count(*) >= 5
   ORDER BY intentos_fallidos DESC;
   ```

## Interpretación

Los accesos exitosos y fallidos quedan registrados con hora, PID, rol declarado, base, cliente y regla de `pg_hba.conf` aplicada. La bitácora prueba **desde dónde y con qué nombre de rol** se intentó entrar, no quién era la persona. Antes de esta práctica, el mismo archivo ya contenía rechazos por falta de regla en `pg_hba.conf` (21:18:33–21:19:25) y dos fallos de contraseña de `postgres` (21:24:27 y 21:30:13): fueron intentos de preparación del entorno, algo que la bitácora no puede distinguir de un ataque por sí sola.
