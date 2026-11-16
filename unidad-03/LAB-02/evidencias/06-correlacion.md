# Evidencia 06 — Correlación de un cambio de configuración con su autor

Horas en UTC (hora local = UTC-6).

## Cambios del perfilador en la bitácora

```js
bitacora().filter(e => e.msg === "Profiler settings changed").map(e => ({ t: e.t, ctx: e.ctx, msg: e.msg, attr: e.attr }))
```

| Hora UTC | ctx | Cambio (de → a) | Base |
|---|---|---|---|
| 04:45:03.935 | conn30 | nivel 0 → nivel 2 | comercial |
| 04:45:06.342 | conn46 | nivel 2 → nivel 0 | comercial |
| 04:45:06.365 | conn48 | nivel 0 → nivel 1 con filtro `op $in [insert, remove, update]` | comercial |

La línea del evento **no incluye el usuario**, pero sí el contexto `ctx` (la conexión).

## Autenticación de cada conexión

```js
bitacora().filter(e => e.ctx === "<ctx>" && e.msg === "Successfully authenticated")
```

| ctx | Hora UTC de la autenticación | Usuario | Base de autenticación | Cliente |
|---|---|---|---|---|
| conn30 | 04:45:03.775 | admin | admin | 172.17.0.1:43946 |
| conn46 | 04:45:06.206 | admin | admin | 172.17.0.1:44198 |
| conn48 | 04:45:06.347 | admin | admin | 172.17.0.1:44222 |

Los tres cambios los produjeron conexiones autenticadas como **`admin@admin`**. Los cambios hechos en la Actividad 7 (niveles 2 y 1) no aparecen porque esta consulta se ejecutó antes.

## Respuestas

**1. ¿Qué usuario cambió la configuración del perfilador? ¿Qué dos eventos lo demuestran?**

El usuario **`admin`** (base `admin`). Por ejemplo, para el cambio que aplicó el filtro (nivel 1):
1. `Profiler settings changed` en `conn48` (04:45:06.365), con `attr.from` y `attr.to`.
2. `Successfully authenticated` en la misma conexión `conn48` (04:45:06.347), con `user: admin`, `db: admin`.

Ambos eventos comparten el `ctx`, y la autenticación es anterior al cambio.

**2. ¿Qué condición debe cumplirse para que esta correlación sea válida?**

- Los dos eventos deben pertenecer a **la misma ejecución del servidor**: los números de conexión (`connN`) se reinician cuando el servidor se reinicia, así que `conn48` antes y después de un reinicio sería otra conexión distinta.
- Ambos eventos deben seguir disponibles en el registro consultado (en `getLog` solo hay 1024 eventos en memoria; el evento de autenticación podría haberse desplazado).
- La conexión debe haberse autenticado una sola vez como ese usuario; si cambiara de identidad en la misma conexión habría que revisar el orden temporal de los eventos.

**3. ¿Por qué es relevante que quede registrado un cambio de configuración del propio mecanismo de registro?**

Porque quien quiere ocultar su actividad puede apagar o reducir el registro antes de actuar. Que el cambio quede registrado permite detectar ese hueco de evidencia: aquí se ve que el nivel pasó de 2 a 0 y luego a 1 con filtro, y quién lo hizo. Sin ese registro, un periodo sin datos en `system.profile` no tendría explicación.
