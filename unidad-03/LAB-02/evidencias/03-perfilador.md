# Evidencia 03 — Perfilador nivel 2

Horas de `ts` en UTC; hora local = UTC-6.

## Activación

```js
db.setProfilingLevel(2)
db.getProfilingStatus()
```

```text
{ "was": 0, "slowms": 100, "sampleRate": 1, "ok": 1 }     // setProfilingLevel: was = nivel ANTERIOR
{ "was": 2, "slowms": 100, "sampleRate": 1, "ok": 1 }     // getProfilingStatus: nivel vigente
```

## Operaciones de la aplicación

```bash
mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ ciudad: "Culiacán" }, { nombre: 1, ciudad: 1 }).toArray(); db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XYZ" } }); db.clientes.deleteOne({ _id: 2 });'
```

## Consulta de `system.profile` (resumen de la salida real)

```js
db.system.profile.find({ ns: "comercial.clientes" }, { op: 1, ns: 1, command: 1, user: 1, client: 1, appName: 1, ts: 1, millis: 1, nreturned: 1, docsExamined: 1, nModified: 1, ndeleted: 1 }).sort({ ts: 1 })
```

```text
{ op: "query",  ns: "comercial.clientes", command: { find: "clientes", filter: { ciudad: "Culiacán" }, projection: { nombre: 1, ciudad: 1 }, lsid: {...}, $db: "comercial" },
  docsExamined: 5, nreturned: 3, millis: 0, ts: 2026-11-16T04:45:04.531Z, client: "172.17.0.1", appName: "app-ventas-web", user: "app_ventas@comercial" }
{ op: "update", ns: "comercial.clientes", command: { q: { _id: 3 }, u: { $set: { rfc: "GAMA780912XYZ" } }, multi: false, upsert: false },
  docsExamined: 1, nModified: 1, millis: 0, ts: 2026-11-16T04:45:04.538Z, client: "172.17.0.1", appName: "app-ventas-web", user: "app_ventas@comercial" }
{ op: "remove", ns: "comercial.clientes", command: { q: { _id: 2 }, limit: 1 },
  docsExamined: 1, ndeleted: 1, millis: 0, ts: 2026-11-16T04:45:04.545Z, client: "172.17.0.1", appName: "app-ventas-web", user: "app_ventas@comercial" }
```

Respaldo de este estado: `evidencias/system-profile-nivel2.json`.

## 9.1 Interpretación de los documentos

| # | op | Usuario | Cliente | Aplicación | Momento (UTC / local) | Qué hizo | Documentos afectados |
|---|---|---|---|---|---|---|---|
| 1 | query | app_ventas@comercial | 172.17.0.1 | app-ventas-web | 04:45:04.531 / 22:45:04.531 | `find` de clientes con `ciudad: "Culiacán"`, proyectando `nombre` y `ciudad` | 5 examinados, 3 devueltos |
| 2 | update | app_ventas@comercial | 172.17.0.1 | app-ventas-web | 04:45:04.538 / 22:45:04.538 | `$set rfc: "GAMA780912XYZ"` sobre `_id: 3` (`multi: false`, `upsert: false`) | 1 examinado, 1 modificado |
| 3 | remove | app_ventas@comercial | 172.17.0.1 | app-ventas-web | 04:45:04.545 / 22:45:04.545 | Eliminación de `_id: 2` (`limit: 1`) | 1 examinado, 1 eliminado |

Nota sobre `client`: aparece `172.17.0.1` y no `127.0.0.1` porque el servidor está en un contenedor; esa es la dirección de la puerta de enlace de la red interna de Docker, no la de un equipo remoto.

## Respuestas

**1. ¿Puedes saber cuál era el RFC antes del cambio con la información de `system.profile`?**

**No.** El documento del `update` contiene la condición (`q`) y la modificación (`u: $set rfc: "GAMA780912XYZ"`), es decir, el valor **nuevo**. El perfilador no guarda imágenes previas del documento. Que el valor anterior fuera `GAMA780912XXX` lo sé solo porque yo mismo ejecuté la Actividad 2; no está en la evidencia.

**2. ¿Puedes saber qué datos tenía el documento eliminado?**

**No.** El documento del `remove` solo muestra el filtro (`q: { _id: 2 }`) y que se eliminó 1 documento (`ndeleted: 1`). El contenido eliminado no se registra.

**3. A diferencia de `log_statement = 'mod'` en PostgreSQL, el nivel 2 sí registró la consulta. ¿Qué ventaja y qué riesgo tiene eso?**

- **Ventaja:** permite saber quién leyó datos, cuándo y con qué filtro, y cuántos documentos devolvió (`nreturned`); con `mod` las lecturas no quedan registradas.
- **Riesgo:** los filtros de consulta pueden contener datos personales (nombres, RFC, correos) y quedan guardados en claro en `system.profile`, legibles por quien tenga acceso a esa colección. Además, el nivel 2 degrada el rendimiento y llena rápidamente la colección limitada de 1 MB, de modo que el nivel 2 sobrescribe evidencia antigua.

**4. ¿Por qué el campo `user` incluye `@comercial`?**

Porque en MongoDB la identidad de un usuario es **nombre + base de datos donde se definió** (`usuario@base`). `app_ventas@comercial` indica que el usuario se creó y autentica en la base `comercial`; podría existir otro `app_ventas` en otra base y ser un usuario distinto.
