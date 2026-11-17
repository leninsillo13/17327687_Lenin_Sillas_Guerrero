# Informe — LAB-02 Trazabilidad en MongoDB Community

Materia: Gestión de Seguridad y Desempeño de Bases de Datos — Unidad III
Fecha de ejecución: 2026-11-15 (hora local, UTC-6)

## 1. Despliegue, edición y limitación

El servidor se desplegó como contenedor Docker con la imagen oficial `mongo:7` (`docker run --name dba-u3-mongo -p 27017:27017 -d mongo:7 --auth`), en Windows con Docker Desktop, y se operó con `mongosh` 2.14.2 desde Git Bash. La versión es 7.0.48 y la autorización está habilitada.

**Hecho verificado:** la edición es Community, porque `buildInfo.modules` devuelve `[]` (en Enterprise incluiría `"enterprise"`). La auditoría nativa de MongoDB existe solo en Enterprise y Atlas (M10 o superior) según REF-U3-04, por lo que **no está disponible** en este servidor. El laboratorio usó el perfilador y la bitácora de `mongod`, que **no son equivalentes** a ella.

## 2. Perfilador

**Configuración.** Con el perfilador apagado (`was: 0`) un cambio de RFC no dejó ninguna evidencia (`system.profile` con 0 documentos). Con el nivel 2 se registraron un `query`, un `update` y un `remove` de `app_ventas@comercial`, con cliente, aplicación (`app-ventas-web`) y hora. Luego se aplicó un nivel 1 con filtro sobre `insert`, `update` y `remove`, que registró solo el `update`.

**Interpretación.** El perfilador permite saber quién (cuenta), cuándo, con qué aplicación y con qué filtro y valor nuevo se modificó un dato. No guarda el valor anterior ni el contenido eliminado. El campo `client` mostró `172.17.0.1`, la puerta de enlace de Docker, y `appName` es declarado por el cliente.

**Costo.** El nivel 2 registra todo, degrada el rendimiento (según REF-U3-05), llena rápidamente la colección de 1 MB y guarda en claro los filtros de las consultas, que pueden contener datos personales. El filtro reduce volumen y exposición, pero pierde las lecturas, los comandos y las operaciones lentas.

## 3. Bitácora de mongod

**Dónde se escribe.** En la salida estándar del proceso (no hay sección `systemLog` en `serverCmdLineOpts().parsed`), consultable con `docker logs dba-u3-mongo`. Desde `mongosh` se leyó con `getLog` (481 eventos en memoria antes del reinicio).

**Accesos.** Se observaron accesos exitosos (`Successfully authenticated`, `result: 0`) y fallidos (`Failed to authenticate`, con `result: 18` para contraseña incorrecta y `11` para usuario inexistente). Un intento puede producir varias líneas, por lo que se cuentan intentos, no líneas.

**Cambios de configuración.** `Profiler settings changed` registra el cambio (`from`/`to`) pero no el usuario. Al correlacionar su `ctx` con `Successfully authenticated`, los tres cambios de la corrida resultaron ser del usuario `admin`. La correlación solo es válida dentro de la misma ejecución del servidor y mientras ambos eventos sigan en el registro consultado.

## 4. Privilegios

**Evidencia disponible.** Al otorgar `dbAdmin` a `app_ventas`, ni el perfilador (nivel 2 activo) ni la bitácora contenían el evento (0 y 0).

**Control compensatorio.** Dos instantáneas de privilegios, tomadas antes y después, permitieron detectar el cambio y el rol agregado, pero no el autor ni la hora exacta (solo un intervalo de aproximadamente 60 ms entre ambas).

**Límite.** Las instantáneas no son auditoría: no dan autor ni momento. Además, la función `db.getUsers()` solo cubrió la base `comercial`, de modo que `admin` quedó fuera, y las instantáneas las escribió `admin`, sin separación de funciones.

## 5. Conservación

**Riesgos observados.** Tras reiniciar el contenedor, el perfilador volvió al nivel 0 (el nivel no persiste), la memoria de `getLog` pasó de 481 a 96 eventos, y los documentos de `system.profile` se conservaron (2). Además, `system.profile` es una colección limitada de 1 MB que sobrescribe lo más antiguo sin aviso, y la bitácora en salida estándar depende de que el contenedor exista.

**Exportación realizada.** Se exportaron `system-profile.json` y `bitacora-mongod.log` antes del reinicio, con sus hashes SHA-256 en `hashes.sha256`. No se aplicó la configuración persistente opcional.

## 6. Comparación

Resumen de la Actividad 9 (detalle en `evidencias/09-comparacion.md`). En MongoDB Community se observó: accesos exitosos y fallidos (sí), modificación de datos (sí, valores nuevos), lecturas (parcial, solo en nivel 2), cambio de configuración del registro (sí, mediante correlación), cambio de privilegios (no; solo el control compensatorio de instantáneas detecta qué cambió, sin autor ni hora exacta) y valor anterior (no). El cambio de estructura no se verificó.

En PostgreSQL (LAB-01, `log_statement = mod` con disparador de auditoría) sí se demostraron accesos exitosos y fallidos, cambios de privilegios (línea 349) y de estructura (línea 350), modificaciones de datos (línea 382) y el valor anterior (evento 1 de `auditoria.cambios_clientes`); la lectura de datos sensibles no quedó registrada y el cambio de configuración quedó parcialmente (la sentencia sí, el mensaje de recarga no). La columna de Enterprise/Atlas es "documentado, no practicado".

Las diferencias relevantes son tres: PostgreSQL atribuye privilegios y estructura y conserva el valor anterior, y Community no tiene equivalente para esos eventos; ambos motores comparten la limitación de la lectura de datos; y en ambos el administrador con control total puede desactivar el mecanismo.

## 7. Recomendación

Para una organización que necesite auditar cambios de privilegios en MongoDB, recomendaría **usar auditoría nativa de Enterprise o Atlas** si existe un requisito normativo, contractual o de riesgo que exija saber quién cambió un privilegio y cuándo.

**Por qué, con hechos verificados:**
- En este laboratorio, un cambio de privilegios no dejó ningún rastro en el perfilador ni en la bitácora (0 y 0).
- Las instantáneas detectaron el cambio y el rol, pero no el autor ni la hora exacta.

**Si no es viable cambiar de edición**, aceptar formalmente el riesgo y mantener controles compensatorios: instantáneas periódicas de **todas** las bases con usuarios (incluida `admin`), escritas por una cuenta dedicada y enviadas a un almacén externo con escritura protegida; exportación periódica de la bitácora con hash; y restricción y registro de quién puede usar cuentas con privilegios de administración.

**Supuestos (no verificados en este laboratorio):**
- Que la auditoría nativa registra los cambios de privilegios dentro de las categorías de autenticación, autorización o DDL de REF-U3-04: es lo que dice la documentación, pero no se practicó.
- La frecuencia de instantáneas sugerida (diaria o cada hora, según criticidad) es un punto de partida, no una medición.
- La columna de PostgreSQL de la comparación se tomó del informe del LAB-01 y se cita por sus líneas; no se volvió a ejecutar en este laboratorio.
- El alcance de la auditoría nativa por evento se tomó de REF-U3-04 y del resumen de la materia ("documentado", no practicado); no se verificó en un servidor Enterprise o Atlas.

## Preguntas de reflexión

**1. ¿Por qué el perfilador no debe presentarse como un mecanismo de auditoría de seguridad?**
Fue diseñado para analizar desempeño. No registra eventos de privilegios (0 resultados), no guarda el valor anterior, se sobrescribe solo por su tamaño, se apaga con un reinicio y su configuración puede ser modificada por un administrador.

**2. ¿Por qué el perfilador sí aporta trazabilidad aunque no sea auditoría?**
Porque con él se pudo atribuir un `update` y un `remove` a una cuenta, una aplicación y una hora, algo imposible con el perfilador apagado.

**3. ¿Qué riesgo introduce el nivel 2 al registrar filtros de consultas que pueden contener datos personales?**
Que esos datos queden guardados en claro en `system.profile`, accesibles para quien pueda leer esa colección, ampliando la exposición de información personal.

**4. ¿Qué diferencia hay entre detectar un cambio y atribuirlo a alguien?**
Detectar es saber que algo cambió (las instantáneas lo lograron con los privilegios); atribuir es identificar quién, cuándo y desde dónde lo hizo, y eso requiere un registro del evento, que Community no tiene para los privilegios.

**5. ¿Por qué reconocer una limitación técnica es parte del trabajo profesional del DBA?**
Porque presentar un control parcial como completo da una falsa seguridad a Dirección; documentar la limitación permite decidir con información real si se acepta el riesgo, se compensa o se cambia de herramienta.
