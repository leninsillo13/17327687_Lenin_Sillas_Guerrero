# Evidencia 08 — Conservación de evidencias

## 14.1 El nivel del perfilador no sobrevive al reinicio

Reinicio ejecutado con `docker restart dba-u3-mongo`.

| Medida | Antes del reinicio | Después del reinicio |
|---|---|---|
| `getProfilingStatus()` | nivel 1 con filtro (`was: 1`) | **nivel 0** (`was: 0`) |
| `system.profile.countDocuments()` | 2 | 2 |
| `bitacora().length` (eventos en memoria) | 481 | **96** |

- El perfilador volvió al nivel 0: el nivel puesto con `setProfilingLevel()` no persiste.
- Los documentos ya registrados en `system.profile` siguieron ahí (2).
- La memoria de `getLog` se vació: de 481 a 96 eventos.

No apliqué la configuración persistente opcional (`systemLog` y `operationProfiling` en un archivo de configuración): el contenedor se arrancó solo con `--auth`, y `serverCmdLineOpts().parsed` solo muestra `net` y `security`. No se cambió ningún archivo.

## 14.2 y 14.3 Exportaciones

Se exportaron **antes** del reinicio:

| Archivo | Contenido |
|---|---|
| `evidencias/system-profile.json` | `system.profile` (campos op, ns, user, client, appName, ts, command.q, command.u) |
| `evidencias/bitacora-mongod.log` | Eventos de `getLog` (481 en el momento de exportar) |

Hashes SHA-256 (`evidencias/hashes.sha256`):

```text
ee643d3326e665662da70e7a06ee8ac9135a61f87268e7125ae112850a7f5790  system-profile.json
6a6e6cbdff889cd5859b9e56bc1913091ff5819c3e753be784b3d01c0cef34c6  bitacora-mongod.log
411772495dda10d7b4d3c99d34bd7326bdffd747ff6c2b3452228f703467d738  system-profile-nivel2.json
```

Los tres hashes son distintos, lo que indica que los archivos tienen contenido distinto.

Como el servidor escribe su bitácora en la salida estándar, existe una copia más completa en `docker logs dba-u3-mongo` mientras el contenedor exista; en este laboratorio no la exporté.

## Respuestas

**1. Menciona tres formas en que la evidencia del perfilador o de la bitácora puede perderse sin que nadie la borre deliberadamente.**

1. **Sobrescritura de `system.profile`**: es una colección limitada de 1 MB; al llenarse, los documentos más antiguos se reemplazan por los nuevos.
2. **Reinicio del servidor**: la memoria que consulta `getLog` se vacía (de 481 a 96 eventos en esta corrida) y el perfilador vuelve al nivel 0, de modo que deja de registrar sin aviso.
3. **Pérdida de la salida estándar del contenedor**: si el contenedor se elimina o su registro rota (límites de tamaño de los registros de Docker), la bitácora desaparece.

**2. ¿Por qué el tamaño de 1 MB de `system.profile` es un problema de conservación y no solo de espacio?**

Porque la sobrescritura elimina primero lo más antiguo, que puede ser justamente el incidente que se investiga, y ocurre **sin alertas ni registro**: no se sabe qué periodo ya se perdió. Con nivel 2 o con mucha actividad, la ventana de evidencia puede reducirse a minutos. El problema no es solo cuánto disco ocupa, sino que no se puede garantizar cuánto tiempo hacia atrás se conserva.

**3. ¿Por qué `getLog` sirve para interpretar pero no para conservar?**

Sirve para consultar rápidamente los eventos recientes y filtrarlos desde `mongosh`. No sirve para conservar porque solo guarda los 1024 eventos más recientes en memoria, se vacía al reiniciar y no es una copia completa ni protegida contra alteraciones. Para conservar hay que exportarlo y calcular su hash, o preservar el archivo o flujo real de la bitácora.
