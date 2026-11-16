# Evidencia 01 — Edición de MongoDB y limitación de auditoría

Fecha de ejecución: 2026-11-15, 22:44 (hora local, UTC-6). Servidor: contenedor Docker `dba-u3-mongo` (`mongo:7`).

## Comandos ejecutados (sesión del DBA)

```js
db.version()
db.adminCommand({ buildInfo: 1 }).modules
db.serverCmdLineOpts().parsed
```

## Salida observada

```text
7.0.48
[]
{
  "net": { "bindIp": "*" },
  "security": { "authorization": "enabled" }
}
```

## Respuestas

**1. ¿Qué edición de MongoDB estás usando? ¿Qué evidencia lo demuestra?**

Uso **MongoDB 7.0.48 Community Edition**. La evidencia es que `buildInfo.modules` devuelve un arreglo vacío (`[]`); en una edición Enterprise incluiría `"enterprise"`. Además, la imagen usada es la oficial `mongo:7` (Community).

**2. ¿A dónde escribe tu servidor su bitácora? ¿Cómo lo sé?**

Escribe en la **salida estándar** del proceso `mongod`. Lo sé porque `db.serverCmdLineOpts().parsed` solo muestra las secciones `net` y `security`: no existe la sección `systemLog` (ni `destination` ni `path`), y sin esa configuración `mongod` escribe en la salida estándar. Al ser un contenedor, esa salida se consulta con `docker logs dba-u3-mongo`. Desde `mongosh`, `getLog` solo devuelve los eventos recientes en memoria.

**3. Según REF-U3-04, ¿qué cuatro categorías de eventos registraría la auditoría nativa?**

1. Cambios de esquema (DDL).
2. Eventos de conjuntos de réplicas y clústeres fragmentados.
3. Autenticación y autorización.
4. Operaciones CRUD (requiere `auditAuthorizationSuccess: true`).

**4. ¿Qué tendría que evaluar una organización antes de licenciar Enterprise o migrar a Atlas solo para obtener auditoría?**

- **Costo**: licencia de Enterprise o clústeres Atlas M10 o superiores, frente al riesgo que se quiere cubrir.
- **Requisito real**: si una norma, contrato o auditoría exige trazabilidad nativa de accesos, privilegios o CRUD, o si bastan controles compensatorios.
- **Impacto en desempeño y volumen**: sobre todo al auditar CRUD, que genera muchos eventos.
- **Esfuerzo de migración u operación**: cambio de edición o de plataforma, compatibilidad con la aplicación, soporte y capacitación.
- **Destino y custodia de los eventos**: consola, syslog, archivo JSON o BSON; retención, integridad y quién puede leerlos.

## Observación adicional

`bindIp` aparece como `*`: el servidor escucha en todas las interfaces del contenedor. Es la configuración por defecto de la imagen y es aceptable en este entorno de práctica, pero en producción conviene restringirlo.

## Conclusión

La auditoría nativa **no existe** en MongoDB Community. Este laboratorio trabaja con el perfilador y la bitácora de `mongod`, que aportan trazabilidad parcial pero **no son equivalentes** a la auditoría nativa.
