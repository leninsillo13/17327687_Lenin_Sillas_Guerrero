# Evidencia 07 — Cambios de privilegios y control compensatorio

Horas en UTC (hora local = UTC-6).

## Procedimiento

1. Instantánea 1 de privilegios, en la colección `auditoria.instantaneas_privilegios`.
2. Nivel de perfilado 2 y `db.grantRolesToUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])`.
3. Búsqueda de evidencia del cambio en el perfilador y en la bitácora.
4. Instantánea 2 y comparación.
5. Reversión: `revokeRolesFromUser` y restablecimiento del filtro.

## Búsqueda de evidencia del cambio

```js
db.system.profile.countDocuments({ "command.grantRolesToUser": { $exists: true } })
bitacora().filter(e => JSON.stringify(e).includes("grantRoles")).length
```

```text
0
0
```

**No hay evidencia en ninguna de las dos fuentes.**

## Instantáneas

| Instantánea | Momento (UTC) | Tomada por | Roles de `app_ventas@comercial` |
|---|---|---|---|
| 1 | 2026-11-16T04:45:10.287Z | admin@admin | `readWrite@comercial` |
| 2 | 2026-11-16T04:45:10.347Z | admin@admin | `readWrite@comercial`, `dbAdmin@comercial` |

| Pregunta | ¿La instantánea responde? |
|---|---|
| ¿Cambiaron los privilegios de `app_ventas`? | **Sí** (se agregó un rol entre las dos instantáneas) |
| ¿Qué rol se agregó? | **Sí**: `dbAdmin` en `comercial` |
| ¿Quién lo agregó? | **No** (el campo `tomada_por` dice quién tomó la instantánea, no quién hizo el cambio) |
| ¿Cuándo exactamente? | **No**: solo que ocurrió entre las 04:45:10.287 y las 04:45:10.347 |

Estado tras la reversión: `app_ventas` volvió a tener solo `readWrite@comercial` y el perfilador quedó con el nivel 1 y el filtro de la Actividad 4.

## Limitación adicional observada

Las instantáneas solo listan a `app_ventas`. La función `db.getUsers()` devuelve los usuarios de la **base activa** (`comercial`, por la cadena de conexión), por lo que el usuario `admin`, definido en la base `admin`, **no está cubierto**. Una instantánea completa debería recorrer también la base `admin` (por ejemplo, con `db.getSiblingDB("admin").getUsers()`). No lo probé en este laboratorio.

## Respuestas

**1. ¿Por qué un cambio de privilegios es uno de los eventos auditables más importantes?**

Porque cambia lo que una cuenta puede hacer a partir de ese momento: es la vía para escalar privilegios (propios o ajenos), dejar acceso persistente y preparar otras acciones sin dejar rastro. Detectar y atribuir esos cambios es la base para controlar quién tiene poder sobre los datos. En este laboratorio, un rol `dbAdmin` apareció en `app_ventas` sin dejar ningún rastro en el perfilador ni en la bitácora.

**2. ¿Con qué frecuencia tomarías instantáneas? ¿Qué factores influyen?**

Dependería del riesgo y se definiría por política; como punto de partida razonable (supuesto, no verificado en el laboratorio), una vez al día en entornos de riesgo moderado y cada hora o menos en entornos críticos. Influyen: la criticidad de los datos, la frecuencia habitual de cambios de privilegios, el tiempo máximo aceptable para detectar un cambio indebido, los requisitos normativos, el volumen de usuarios (costo de cada instantánea) y la retención. Una frecuencia más alta reduce el intervalo de incertidumbre sobre el momento del cambio, pero nunca da el autor.

**3. ¿Quién debería poder escribir en `auditoria.instantaneas_privilegios`?**

Solo una cuenta o proceso dedicado y de privilegio mínimo (solo insertar), separado de los DBA cuya actividad se supervisa y de la aplicación. En este laboratorio las escribió `admin` (root), que es justamente quien puede cambiar privilegios: no hay separación de funciones. Lo ideal es enviarlas además a un almacén externo con escritura protegida, porque quien tiene privilegios sobre `auditoria` podría modificarlas.

**4. Redacta en tres líneas cómo comunicarías esta limitación a Dirección.**

1. Con MongoDB Community podemos detectar que los privilegios de una cuenta cambiaron y qué rol se agregó, comparando instantáneas periódicas.
2. No podemos saber quién lo hizo ni a qué hora exacta: la edición Community no registra esos eventos, y ninguna de sus fuentes (perfilador, bitácora) los contiene.
3. Para obtener autor y hora necesitamos auditoría nativa (Enterprise o Atlas) o aceptar formalmente este riesgo con los controles compensatorios documentados.
