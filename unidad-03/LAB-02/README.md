# LAB-02 — Trazabilidad en MongoDB Community

Materia: Gestión de Seguridad y Desempeño de Bases de Datos
Unidad III — Auditoría, trazabilidad y gobierno práctico de datos

## Despliegue utilizado

- Forma de despliegue: Contenedor Docker `mongo:7` sobre Windows (Docker Desktop), comandos ejecutados desde Git Bash con `mongosh` 2.14.2 (`docker run --name dba-u3-mongo -p 27017:27017 -d mongo:7 --auth`)
- Versión (`db.version()`): 7.0.48
- Edición: MongoDB Community (`buildInfo.modules` devuelve `[]`)
- Autorización: `security.authorization: enabled`
- Destino de la bitácora: salida estándar del proceso (`serverCmdLineOpts().parsed` no muestra la sección `systemLog`); se consulta con `docker logs dba-u3-mongo`

## Contenido

| Ruta | Descripción |
|---|---|
| `evidencias/01-edicion-y-limitacion.md` | Edición y limitación de auditoría |
| `evidencias/02-incidente-sin-perfilado.md` | Incidente sin perfilado |
| `evidencias/03-perfilador.md` | Perfilador nivel 2 |
| `evidencias/04-filtro.md` | Perfilador con filtro |
| `evidencias/05-accesos-mongod.md` | Accesos en la bitácora |
| `evidencias/06-correlacion.md` | Correlación por `ctx` |
| `evidencias/07-privilegios-control-compensatorio.md` | Instantáneas de privilegios |
| `evidencias/08-conservacion.md` | Conservación de evidencias |
| `evidencias/09-comparacion.md` | Comparación de tres escenarios |
| `evidencias/10-respuesta-direccion.md` | Respuesta a Dirección |
| `evidencias/system-profile.json` | Exportación de `system.profile` |
| `evidencias/bitacora-mongod.log` | Exportación de la bitácora |
| `evidencias/hashes.sha256` | Hashes SHA-256 |
| `scripts/comandos-mongosh.js` | Comandos usados en el laboratorio |
| `informe.md` | Informe final |

## Nota sobre credenciales

Las contraseñas del laboratorio son solo de práctica. En todas las evidencias aparecen como `<REDACTED>`.
