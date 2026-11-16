# Evidencia 02 — El incidente sin perfilado

Todas las horas de la bitácora están en UTC; la hora local es UTC-6 (04:45 UTC = 22:45 local del 2026-11-15).

## Estado inicial del perfilador

```js
db.getProfilingStatus()
```

```text
{ "was": 0, "slowms": 100, "sampleRate": 1, "ok": 1 }
```

`was: 0`: el perfilador está **apagado**.

## Modificación hecha por la aplicación

```bash
mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XXX" } })'
```

```text
{ acknowledged: true, insertedId: null, matchedCount: 1, modifiedCount: 1, upsertedCount: 0 }
```

## Búsqueda de evidencia

```js
db.system.profile.countDocuments()
bitacora().filter(e => JSON.stringify(e).includes("GAMA780912XXX")).length
bitacora().filter(e => JSON.stringify(e).includes("app-ventas-web")).map(e => ({ t: e.t, c: e.c, ctx: e.ctx, msg: e.msg }))
```

Resultado observado (el listado completo está en `salida-lab02.txt`):

```text
0
0
```

Eventos de la bitácora con `app-ventas-web` (resumen):

| Hora UTC | ctx | Componente | Mensaje |
|---|---|---|---|
| 04:45:00.605 | conn9 | NETWORK | client metadata |
| 04:45:00.606 | conn9 | ACCESS | Connection not authenticating |
| 04:45:00.615 / .636 | conn10 | NETWORK / ACCESS | client metadata / Successfully authenticated |
| 04:45:00.755 – .767 | conn11, conn12 | NETWORK / ACCESS | client metadata / Successfully authenticated |
| 04:45:02.525 | conn21 | NETWORK | client metadata |
| 04:45:02.526 | conn21 | ACCESS | Connection not authenticating |
| 04:45:02.534 / .552 | conn22 | NETWORK / ACCESS | client metadata / Successfully authenticated |
| 04:45:02.661 – .670 | conn23, conn24 | NETWORK / ACCESS | client metadata / Successfully authenticated |

Hay dos grupos de conexiones con `app-ventas-web`. Por la hora y porque el script abre esa conexión como verificación previa antes de la Actividad 1, el primer grupo (04:45:00, conn9–conn12) corresponde a esa verificación; el segundo (04:45:02, conn21–conn24) corresponde, por la hora, a la actualización del RFC. Esta asociación es una **inferencia por tiempo**: la bitácora no registra la operación.

## Respuestas

**1. ¿Puedes demostrar qué cambió? ¿Y quién se conectó a esa hora?**

**Qué cambió: no.** `system.profile` tiene 0 documentos y la bitácora no contiene el valor `GAMA780912XXX`. `mongod` no registra por defecto el contenido de las escrituras. **No hay evidencia con esta edición** (con el perfilador apagado) de la operación, del valor nuevo ni del valor anterior.

**Quién se conectó: parcialmente.** La bitácora muestra conexiones con `appName` `app-ventas-web` y eventos `Successfully authenticated` a las 04:45:02 UTC. Eso prueba que alguien se conectó y se autenticó con esa identificación de aplicación, pero **no** que esas conexiones hayan ejecutado la actualización: no hay vínculo entre conexión y operación.

**2. ¿Por qué mongosh abre varias conexiones (conn8, conn9, …) para una sola instrucción? ¿Cuál es la que se autentica?**

Un mismo `mongosh` abre varias conexiones: una de **monitoreo/descubrimiento** del servidor (envía los metadatos del cliente y no se autentica: `Connection not authenticating`, en esta corrida conn21) y otras de **trabajo**, por las que se autentica y se ejecuta la instrucción. En esta corrida se autenticaron tres conexiones por invocación (conn22, conn23 y conn24). Como la bitácora no registra la operación, no puede saberse cuál de ellas la ejecutó.

## Conclusión

Sin perfilador activo, la única huella es el patrón de conexión y autenticación. Se detecta que hubo actividad, pero no se puede demostrar qué se cambió, quién lo cambió ni el valor anterior.
