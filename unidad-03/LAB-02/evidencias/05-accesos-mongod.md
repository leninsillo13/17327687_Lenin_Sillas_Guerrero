# Evidencia 05 — Accesos en la bitácora de mongod

Horas en UTC (hora local = UTC-6).

## Intentos fallidos generados

```bash
mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
mongosh "mongodb://usuario_inexistente:<REDACTED>@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
```

Salida en ambos casos: `MongoServerError: Authentication failed.`

## Accesos fallidos en la bitácora

```js
bitacora().filter(e => e.c === "ACCESS" && e.msg === "Failed to authenticate")
```

| Hora UTC | id | ctx | Usuario | Cliente | Error | result | isSpeculative | Aplicación |
|---|---|---|---|---|---|---|---|---|
| 04:45:07.969 | 5286307 | conn58 | app_ventas | 172.17.0.1:44414 | AuthenticationFailed: SCRAM authentication failed, storedKey mismatch | 18 | true | mongosh 2.14.2 |
| 04:45:08.410 | 5286307 | conn60 | usuario_inexistente | 172.17.0.1:44444 | UserNotFound: Could not find user "usuario_inexistente" for db "comercial" | 11 | true | mongosh 2.14.2 |
| 04:45:08.414 | 5286307 | conn60 | usuario_inexistente | 172.17.0.1:44444 | UserNotFound: Could not find user "usuario_inexistente" for db "comercial" | 11 | false | mongosh 2.14.2 |

Se generaron **2 intentos** fallidos y aparecen **3 líneas**: el usuario inexistente produjo dos (una con `isSpeculative: true` y otra con `false`). Se cuentan intentos, no líneas.

## Último acceso exitoso de la aplicación

```js
bitacora().filter(e => e.msg === "Successfully authenticated" && e.attr.user === "app_ventas").slice(-1)
```

| Hora UTC | id | ctx | Cliente | result | Aplicación |
|---|---|---|---|---|---|
| 04:45:06.920 | 5286306 | conn51 | 172.17.0.1:44270 | 0 | app-ventas-web |

## Respuestas

**1. ¿Qué campo distingue un acceso fallido de uno exitoso?**

El mensaje (`msg`): `Failed to authenticate` frente a `Successfully authenticated`. Lo acompañan el `id` del mensaje (5286307 para fallos y 5286306 para éxitos) y el campo `attr.result`: `0` en el acceso exitoso y distinto de cero en los fallidos (18 y 11 en esta corrida).

**2. ¿Qué diferencia hay entre el error de contraseña incorrecta y el de usuario inexistente? ¿Por qué el cliente recibe el mismo mensaje en ambos casos?**

- Contraseña incorrecta: `AuthenticationFailed: SCRAM authentication failed, storedKey mismatch` (`result: 18`); el usuario existe pero la clave no coincide.
- Usuario inexistente: `UserNotFound: Could not find user "usuario_inexistente" for db "comercial"` (`result: 11`).

El cliente recibe en ambos casos el mismo `Authentication failed` para **no revelar si un usuario existe**; así se evita que un atacante enumere cuentas válidas. El detalle solo queda en la bitácora del servidor, para el DBA.

**3. ¿Por qué el nombre de la aplicación del intento fallido es `mongosh 2.14.2` y no `app-ventas-web`?**

Porque las cadenas de conexión de los intentos fallidos **no incluyen `?appName=`**. Sin ese parámetro, el campo de aplicación que reporta el cliente en sus metadatos es el valor por defecto, el nombre y la versión de la herramienta (`mongosh 2.14.2`). Además, `appName` lo declara el propio cliente, por lo que es útil como pista, pero no es una prueba de identidad.

## Observaciones

- El cliente aparece como `172.17.0.1` por tratarse de un contenedor (puerta de enlace de la red interna de Docker).
- El acceso exitoso muestra usuario, cliente, hora y aplicación, pero no registra qué hizo después esa conexión.
