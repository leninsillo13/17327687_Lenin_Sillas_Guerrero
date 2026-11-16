// LAB-02 — Comandos de mongosh utilizados
// Contraseñas de práctica: sustituir por <REDACTED> en cualquier evidencia.
//
// Sesión del DBA:
//   mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin"
// Sesión de la aplicación:
//   mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web"

// ---------------------------------------------------------------
// 0. Función auxiliar (definir una vez por sesión del DBA)
// ---------------------------------------------------------------
function bitacora() {
  return db.adminCommand({ getLog: "global" }).log.map(l => JSON.parse(l))
}

// ---------------------------------------------------------------
// 6.3 Preparación (conexión local sin credenciales, solo la primera vez)
// ---------------------------------------------------------------
// use admin
// db.createUser({ user: "admin", pwd: "<REDACTED>", roles: ["root"] })
// db.auth("admin", "<REDACTED>")
// use comercial
// db.createUser({ user: "app_ventas", pwd: "<REDACTED>", roles: [{ role: "readWrite", db: "comercial" }] })
// db.clientes.insertMany([ ...ver guía del laboratorio, sección 6.3... ])

// ---------------------------------------------------------------
// Actividad 1 — Edición y limitación
// ---------------------------------------------------------------
db.version()
db.adminCommand({ buildInfo: 1 }).modules
db.serverCmdLineOpts().parsed

// ---------------------------------------------------------------
// Actividad 2 — Incidente sin perfilado
// ---------------------------------------------------------------
db.getProfilingStatus()
// (en terminal, sesión de la aplicación)
// mongosh "<cadena app_ventas>" --quiet --eval 'db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XXX" } })'
db.system.profile.countDocuments()
bitacora().filter(e => JSON.stringify(e).includes("GAMA780912XXX")).length
bitacora().filter(e => JSON.stringify(e).includes("app-ventas-web")).map(e => ({ t: e.t, c: e.c, ctx: e.ctx, msg: e.msg }))

// ---------------------------------------------------------------
// Actividad 3 — Perfilador nivel 2
// ---------------------------------------------------------------
db.setProfilingLevel(2)
db.getProfilingStatus()
// (en terminal, sesión de la aplicación)
// mongosh "<cadena app_ventas>" --quiet --eval 'db.clientes.find({ ciudad: "Culiacán" }, { nombre: 1, ciudad: 1 }).toArray(); db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XYZ" } }); db.clientes.deleteOne({ _id: 2 });'
db.system.profile.find(
  { ns: "comercial.clientes" },
  { op: 1, ns: 1, command: 1, user: 1, client: 1, appName: 1, ts: 1, millis: 1, nreturned: 1, docsExamined: 1, nModified: 1, ndeleted: 1 }
).sort({ ts: 1 })

// ---------------------------------------------------------------
// Actividad 4 — Filtro
// ---------------------------------------------------------------
// ANTES de borrar system.profile, exportar (Actividad 8) o repetir la Actividad 3 después.
db.setProfilingLevel(0)
db.system.profile.drop()
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })
db.getProfilingStatus()
// (en terminal, sesión de la aplicación)
// mongosh "<cadena app_ventas>" --quiet --eval 'db.clientes.find({ _id: 1 }).toArray(); db.clientes.updateOne({ _id: 1 }, { $set: { telefono: "6670000000" } })'
db.system.profile.find({}, { op: 1, ns: 1, user: 1, appName: 1, "command.q": 1, "command.u": 1, ts: 1 })

// ---------------------------------------------------------------
// Actividad 5 — Accesos
// ---------------------------------------------------------------
// (en terminal, dos intentos fallidos)
// mongosh "mongodb://app_ventas:incorrecta@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
// mongosh "mongodb://usuario_inexistente:x@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
bitacora()
  .filter(e => e.c === "ACCESS" && e.msg === "Failed to authenticate")
  .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, user: e.attr.user, client: e.attr.client, error: e.attr.error, result: e.attr.result, app: e.attr.doc.application.name }))

bitacora()
  .filter(e => e.msg === "Successfully authenticated" && e.attr.user === "app_ventas")
  .slice(-1)
  .map(e => ({ t: e.t, id: e.id, ctx: e.ctx, client: e.attr.client, result: e.attr.result, app: e.attr.doc.application.name }))

// ---------------------------------------------------------------
// Actividad 6 — Correlación por ctx
// ---------------------------------------------------------------
bitacora()
  .filter(e => e.msg === "Profiler settings changed")
  .map(e => ({ t: e.t, ctx: e.ctx, msg: e.msg, attr: e.attr }))

// Sustituir conn31 por el ctx obtenido arriba
bitacora()
  .filter(e => e.ctx === "conn31" && e.msg === "Successfully authenticated")
  .map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))

// ---------------------------------------------------------------
// Actividad 7 — Privilegios: control compensatorio
// ---------------------------------------------------------------
// Instantánea 1 (repetir el mismo insertOne para la instantánea 2)
db.getSiblingDB("auditoria").instantaneas_privilegios.insertOne({
  momento: new Date(),
  tomada_por: db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers,
  usuarios: db.getUsers().users.map(u => ({ user: u.user, db: u.db, roles: u.roles }))
})

db.setProfilingLevel(2)
db.grantRolesToUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])

db.system.profile.countDocuments({ "command.grantRolesToUser": { $exists: true } })
bitacora().filter(e => JSON.stringify(e).includes("grantRoles")).length

// Instantánea 2: repetir el insertOne de arriba y comparar
db.getSiblingDB("auditoria").instantaneas_privilegios.find({}, { _id: 0 }).sort({ momento: 1 })

// Restablecer
db.revokeRolesFromUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })

// ---------------------------------------------------------------
// Actividad 8 — Conservación
// ---------------------------------------------------------------
db.getProfilingStatus()
db.system.profile.countDocuments()
bitacora().length

// Exportaciones (en terminal, desde la carpeta LAB-02/):
// mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'EJSON.stringify(db.system.profile.find({}, { op: 1, ns: 1, user: 1, client: 1, appName: 1, ts: 1, "command.q": 1, "command.u": 1 }).toArray(), null, 2)' > evidencias/system-profile.json
// mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.adminCommand({ getLog: "global" }).log.join("\n")' > evidencias/bitacora-mongod.log
// sha256sum evidencias/system-profile.json evidencias/bitacora-mongod.log > evidencias/hashes.sha256
