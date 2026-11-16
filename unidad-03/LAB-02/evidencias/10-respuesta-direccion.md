# Evidencia 10 — Respuesta a Dirección

Responde solo con la evidencia de este laboratorio. Horas en UTC; hora local = UTC-6.

## 1. ¿Quién cambió el RFC de María García?

**Actividad 2 (perfilador apagado): No hay evidencia con esta edición.** `system.profile` tenía 0 documentos y la bitácora de `mongod` no registra el contenido de las escrituras. Solo se observa que hubo conexiones con `appName` `app-ventas-web` autenticadas a las 04:45:02 UTC, lo cual no demuestra que fueran ellas las que ejecutaron el cambio.

**Actividad 3 (perfilador nivel 2): sí hay evidencia.** El documento `update` de `system.profile` muestra que el usuario **`app_ventas@comercial`** modificó el RFC del `_id: 3` a `GAMA780912XYZ`. Se atribuye a la **cuenta**, no a una persona: la usa la aplicación y el perfilador no registra qué persona hizo la solicitud en la tienda.

## 2. ¿Cuándo y desde qué aplicación?

- **Actividad 2:** No hay evidencia de la operación. Por la hora de las conexiones (04:45:02 UTC), el cambio ocurrió alrededor de esa hora, pero es solo una inferencia.
- **Actividad 3:** 2026-11-16T04:45:04.538Z (**22:45:04.538 del 2026-11-15, hora local**), aplicación `app-ventas-web`, cliente `172.17.0.1`.

Precauciones: `appName` lo declara el propio cliente y puede ser cualquier valor; y `172.17.0.1` es la puerta de enlace de la red interna de Docker, por lo que no identifica el equipo real.

## 3. ¿Qué valor tenía antes?

**No hay evidencia con esta edición.** El perfilador registra el valor nuevo (`$set rfc`), no el anterior, y la bitácora no contiene datos de las operaciones. Recuperar el valor anterior requeriría un mecanismo distinto (por ejemplo, un respaldo o un registro de cambios con imagen previa, que no se practicó en este laboratorio).

## 4. ¿Cambió alguien los privilegios de `app_ventas`?

**Sí hubo un cambio, pero No hay evidencia con esta edición de quién ni de la hora exacta.** La comparación de instantáneas muestra que `app_ventas` pasó de `readWrite@comercial` a `readWrite@comercial` + `dbAdmin@comercial` entre las 04:45:10.287Z y las 04:45:10.347Z. Ni el perfilador ni la bitácora registraron la operación (0 resultados en ambos). Que lo hizo `admin` lo sé únicamente porque yo ejecuté el comando durante el laboratorio, no por la evidencia.

## Resumen

| Pregunta | Actividad 2 | Actividad 3 |
|---|---|---|
| ¿Quién? | No hay evidencia con esta edición | Cuenta `app_ventas@comercial` (no una persona) |
| ¿Cuándo? | No hay evidencia (solo hora aproximada por conexiones) | 04:45:04.538Z (22:45:04.538 local) |
| ¿Desde qué aplicación? | No hay evidencia | `app-ventas-web` (declarada por el cliente) |
| ¿Valor anterior? | No hay evidencia con esta edición | No hay evidencia con esta edición |
| ¿Privilegios? | Cambio detectado por instantáneas; autor y hora exacta: No hay evidencia con esta edición | — |
