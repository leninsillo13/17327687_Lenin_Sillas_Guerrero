# Evidencia 04 — Perfilador con filtro

## Aplicación del filtro

```js
db.setProfilingLevel(0)
db.system.profile.drop()
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })
db.getProfilingStatus()
```

Salida observada:

```text
// setProfilingLevel(1, filtro): was = 0 porque justo antes se había puesto el nivel 0
{ "was": 0, "slowms": 100, "sampleRate": 1, "note": "When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.", "ok": 1 }

// getProfilingStatus: nivel vigente
{ "was": 1, "slowms": 100, "sampleRate": 1,
  "filter": { "op": { "$in": ["insert", "remove", "update"] } },
  "note": "When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.", "ok": 1 }
```

## Operaciones de la aplicación

```bash
mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ _id: 1 }).toArray(); db.clientes.updateOne({ _id: 1 }, { $set: { telefono: "6670000000" } })'
```

```js
db.system.profile.find({}, { op: 1, ns: 1, user: 1, appName: 1, "command.q": 1, "command.u": 1, ts: 1 })
```

```text
[ { op: "update", ns: "comercial.clientes",
    command: { q: { _id: 1 }, u: { $set: { telefono: "6670000000" } } },
    ts: 2026-11-16T04:45:06.922Z, appName: "app-ventas-web", user: "app_ventas@comercial" } ]
```

Solo aparece la operación `update`; el `find` no se registró.

## Respuestas

**1. ¿Qué perdiste de evidencia al aplicar el filtro? ¿Qué ganaste?**

**Perdí:**
- Las lecturas (`query`): ya no hay rastro de quién consultó datos ni con qué filtro (el `find` de `_id: 1` no quedó registrado).
- Cualquier operación que no sea `insert`, `update` o `remove`, como los comandos (`command`) administrativos y de estructura.
- Las operaciones lentas: con un filtro, `slowms` y `sampleRate` no se usan, así que una consulta lenta tampoco se registra por esa vía.
- El contenido previo de `system.profile`, que se borró con `drop()`;.

**Gané:**
- Menor volumen y menor costo de rendimiento que el nivel 2.
- Más tiempo de retención útil dentro del límite de 1 MB, al no gastarlo en lecturas.
- Menos datos personales guardados en claro, porque los filtros de las consultas ya no se registran.

**2. ¿Qué filtro usarías si solo interesaran operaciones sobre la colección `clientes`?**

Uno sobre el campo `ns`, por ejemplo:

```js
db.setProfilingLevel(1, { filter: { ns: "comercial.clientes" } })
```

O, para modificaciones solo de esa colección:

```js
db.setProfilingLevel(1, { filter: { ns: "comercial.clientes", op: { $in: ["insert", "update", "remove"] } } })
```
