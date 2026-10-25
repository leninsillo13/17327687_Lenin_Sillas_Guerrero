# Informe: LAB-04 Hardening y configuración segura de PostgreSQL

## Actividad 1: Identificar la superficie de ataque

**Entorno:** PostgreSQL 18.6 sobre Windows x86_64, administrado con pgAdmin 4.

| Elemento | Estado actual | ¿Es necesario? | Riesgo |
|---|---|---|---|
| Puerto PostgreSQL | 5432 (por defecto) | Sí, pero restringido | Bajo/Medio |
| Interfaces de escucha | `*` (todas) | No, solo se usa localhost | Alto |
| Conexiones remotas | Ninguna activa (solo `::1`) | No | Medio |
| Usuarios administrativos | `postgres` usado como cuenta de trabajo | No debería | Alto |
| SSL/TLS | `off` | Sí | Medio/Alto |
| Métodos de autenticación | `scram-sha-256` | Sí | Bajo |

![Superficie de ataque](evidencias/superficie-ataque.png)

**¿Por qué conocer la superficie de ataque debe preceder al hardening?**

Porque no se puede proteger lo que no se conoce. Antes de cerrar o restringir
algo, hay que saber qué está expuesto (puerto, interfaces de escucha, reglas de
acceso, cuentas con privilegios) y cuáles de esos puntos se usan realmente. Así
se evita bloquear servicios legítimos y se priorizan los cambios según el riesgo
real. En este laboratorio, el inventario inicial mostró que el servidor escucha
en todas las interfaces (`listen_addresses = '*'`), no usa TLS (`ssl = off`) y
que todos los clientes se conectan desde `::1` (localhost), lo que demostró que
la exposición en red era innecesaria.

## Actividad 2: Identificar los archivos de configuración

| Parámetro | Ruta / valor | Categoría |
|---|---|---|
| `data_directory` | `C:/Program Files/PostgreSQL/18/data` | Datos |
| `config_file` | `C:/Program Files/PostgreSQL/18/data/postgresql.conf` | Configuración |
| `hba_file` | `C:/Program Files/PostgreSQL/18/data/pg_hba.conf` | Autenticación |
| `ident_file` | `C:/Program Files/PostgreSQL/18/data/pg_ident.conf` | Autenticación (mapeo de usuarios) |
| `log_directory` | `log` (relativa al directorio de datos: `C:/Program Files/PostgreSQL/18/data/log`) | Logs |
| `log_connections` | vacío (equivale a desactivado en PostgreSQL 18) | Logs |
| `log_disconnections` | `off` | Logs |

**Observación:** los cuatro tipos de archivo están dentro del mismo directorio de datos. Quien obtenga acceso de lectura a esa carpeta podría ver la configuración, las reglas de autenticación y los datos. Además, el servidor no registra conexiones ni desconexiones, así que no habría rastro de quién se conectó.

**¿Por qué es importante conocer la ubicación física de estos archivos?**

Porque la seguridad de PostgreSQL no depende solo de la base de datos, sino también del sistema operativo. `pg_hba.conf` define quién puede conectarse, `postgresql.conf` define cómo se comporta el servidor y el directorio de datos contiene la información real. Si no se sabe dónde están, no se pueden revisar sus permisos, respaldar antes de modificar, ni vigilar cambios no autorizados. Además, distinguir datos, configuración, autenticación y logs permite aplicar controles distintos a cada uno (por ejemplo, proteger la configuración contra escritura y los logs contra borrado).

## Actividad 3: Revisar `listen_addresses`

**Configuración encontrada:** `listen_addresses = '*'`. PostgreSQL escucha en **todas las interfaces**.

**Verificación con `netstat -ano | findstr 5432`:**

| Dirección local | Estado | Significado |
|---|---|---|
| `0.0.0.0:5432` | LISTENING | Escucha en todas las interfaces IPv4 |
| `[::]:5432` | LISTENING | Escucha en todas las interfaces IPv6 |
| `[::1]:5432` ↔ `[::1]:56830`, `56871`, `58544` | ESTABLISHED | Conexiones activas, todas locales (pgAdmin) |

**Interfaces necesarias:** `127.0.0.1` y `::1` (localhost), porque todos los clientes observados (pgAdmin) se conectan desde la propia máquina.

**Interfaces innecesarias:** cualquier otra interfaz de red (Wi-Fi, Ethernet, adaptadores virtuales), ya que ningún cliente remoto las usa.

### Análisis de arquitecturas

**Arquitectura 1:** Internet → Firewall → Servidor PostgreSQL (puerto 5432 alcanzable).
**Arquitectura 2:** Internet ✗ → Firewall → Red privada → Servidor PostgreSQL.

La **arquitectura 2** reduce mejor la exposición, porque:

1. El servidor no es alcanzable directamente desde Internet, así que no puede ser escaneado ni atacado por fuerza bruta desde fuera.
2. Hay varias capas (firewall y red privada), de modo que si una falla, las otras siguen protegiendo (defensa en profundidad).
3. Solo los equipos de la red privada pueden intentar conectarse, lo que reduce el número de posibles atacantes.
4. En la arquitectura 1, la seguridad depende únicamente de contraseñas y reglas de `pg_hba.conf`, mientras que en la 2 además se limita quién puede llegar al puerto.

## Actividad 4: Revisar `pg_hba.conf`

Consulta ejecutada sobre `pg_hba_file_rules`:

| Línea | Tipo | Base de datos | Usuario | Dirección | Máscara | Método | Clasificación |
|---|---|---|---|---|---|---|---|
| 113 | local | all | all | n/a | n/a | scram-sha-256 | Regla local (socket) |
| 115 | host | all | all | 127.0.0.1 | 255.255.255.255 (/32) | scram-sha-256 | IPv4, solo localhost |
| 117 | host | all | all | ::1 | ffff:...:ffff (/128) | scram-sha-256 | IPv6, solo localhost |
| 120 | local | replication | all | n/a | n/a | scram-sha-256 | Replicación local |
| 121 | host | replication | all | 127.0.0.1 | 255.255.255.255 (/32) | scram-sha-256 | Replicación IPv4 local |
| 122 | host | replication | all | ::1 | ffff:...:ffff (/128) | scram-sha-256 | Replicación IPv6 local |

![pg_hba](evidencias/pg-hba.png)

**Hallazgos:**

- **Reglas locales:** 2 (líneas 113 y 120).
- **Reglas IPv4:** 2 (líneas 115 y 121), ambas `127.0.0.1/32`.
- **Reglas IPv6:** 2 (líneas 117 y 122), ambas `::1/128`.
- **Bases de datos afectadas:** `all` y `replication`.
- **Usuarios afectados:** `all`.
- **Redes permitidas:** solo localhost.
- **Método de autenticación:** `scram-sha-256` en todas las reglas.
- **Reglas excesivamente amplias (`0.0.0.0/0` o `::/0`):** ninguna.
- **Campo `error`:** sin errores de sintaxis.

**Conclusión:** el archivo ya limita el origen a localhost y usa un método moderno. Los puntos de mejora son que todas las reglas usan `all` en usuario y base de datos, y que las reglas de `replication` no parecen necesarias. Aunque `pg_hba.conf` rechazaría conexiones remotas, el servidor sigue escuchando en todas las interfaces, por lo que la protección depende de una sola capa.

## Actividad 5: Analizar una regla permisiva

Regla conceptual analizada:

```
host    all    all    0.0.0.0/0    scram-sha-256
```

| Pregunta | Respuesta |
|---|---|
| ¿Qué bases de datos permite? | Todas (`all`), incluidas `postgres`, `template1` y las de otras aplicaciones. |
| ¿Qué usuarios permite? | Todos (`all`), incluidos los superusuarios. |
| ¿Qué direcciones de origen permite? | Cualquier dirección IPv4 (`0.0.0.0/0`). |
| ¿Qué método usa? | `scram-sha-256`: contraseña con intercambio desafío-respuesta, sin enviarla en claro. |
| ¿Por qué es una exposición innecesaria? | Permite que cualquier equipo de Internet intente autenticarse con cualquier usuario sobre cualquier base. La seguridad queda reducida a la contraseña, y quedan expuestas la fuerza bruta, los usuarios por defecto como `postgres` y las vulnerabilidades del servicio. |
| ¿Qué información se necesita para restringirla? | Qué aplicación o persona se conecta, desde qué IP o red, a qué base de datos y con qué usuario. |

**Documentación previa a cualquier cambio:**

- **Regla actual:** en este laboratorio no existe una regla `0.0.0.0/0`. Las reglas actuales son `host all all 127.0.0.1/32` y `host all all ::1/128`, ambas con `scram-sha-256`.
- **Problema:** aunque el origen está limitado, `all`/`all` permite a cualquier usuario local conectarse a cualquier base. Además, `listen_addresses = '*'` hace que el puerto esté alcanzable desde la red.
- **Origen que realmente necesita acceso:** `127.0.0.1` y `::1` (pgAdmin, en la misma máquina).
- **Base de datos:** `laboratorios` (y `postgres` para administración).
- **Usuario:** hoy `postgres`. Debería ser un usuario de aplicación y otro de administración.
- **Regla propuesta:** ver la Actividad 6.

## Actividad 6: Aplicar mínimo privilegio a conexiones (diseño)

Reglas propuestas para el entorno real (pendiente de aplicar en la fase de cambios, una vez creado el rol de aplicación):

```
host    laboratorios    app_lab      127.0.0.1/32    scram-sha-256
host    laboratorios    app_lab      ::1/128         scram-sha-256
host    postgres        dba_lab      127.0.0.1/32    scram-sha-256
host    postgres        dba_lab      ::1/128         scram-sha-256
```

Cada regla restringe los cuatro elementos: **base de datos + usuario + origen + método de autenticación**. Las reglas de `replication` se eliminarían si no se usa replicación. `app_lab` y `dba_lab` son nombres de ejemplo; los roles se crearán en la fase de cambios.

## Actividad 7: Revisar autenticación

**`password_encryption` = `scram-sha-256`.** Las contraseñas nuevas se almacenan con SCRAM-SHA-256, el mecanismo recomendado, y no con `md5`. No requiere cambios.

**¿Qué diferencia existe entre autenticación y autorización?**
La autenticación verifica **quién eres** (usuario y contraseña, certificado). La autorización define **qué puedes hacer** una vez identificado (`GRANT`, atributos del rol, propiedad de objetos). Una conexión puede autenticarse correctamente y aun así no tener permiso para leer una tabla.

**¿Qué protege `scram-sha-256`?**
Protege la contraseña de dos formas. En el servidor se guarda un verificador derivado (sal, iteraciones y claves), no la contraseña. En la red, el cliente demuestra que la conoce mediante un intercambio desafío-respuesta, sin enviarla. Resiste mejor la captura de tráfico y los ataques de diccionario sobre el hash que `md5`. No cifra el resto del tráfico, para eso se necesita TLS.

**¿Por qué una contraseña almacenada mediante un mecanismo de autenticación no debe confundirse con cifrado reversible?**
Porque el verificador es un hash con derivación de clave y no se puede descifrar para recuperar la contraseña. El servidor solo comprueba que la contraseña presentada produce el mismo resultado. El cifrado reversible permite recuperar el texto original con una clave, lo cual sería una debilidad para almacenar credenciales.

**¿Qué sucede si una cuenta tiene permisos excesivos aunque utilice una contraseña fuerte?**
La contraseña fuerte solo dificulta que alguien se haga pasar por la cuenta. Si la cuenta se compromete por otra vía (inyección SQL en la aplicación, credencial filtrada en el código, equipo comprometido), el atacante hereda todos sus permisos. El daño depende de los privilegios, no de la contraseña.

## Actividad 8: Revisar usuarios y privilegios

Roles encontrados (excluyendo los internos `pg_*`):

| Rol | LOGIN | SUPERUSER | CREATEROLE | CREATEDB | REPLICATION | BYPASSRLS | Función |
|---|---|---|---|---|---|---|---|
| `postgres` | Sí | **Sí** | **Sí** | **Sí** | **Sí** | **Sí** | Administrador del servidor. Se usa también como cuenta de trabajo (pgAdmin). |
| `analista` | No | No | No | No | No | No | Rol de grupo, probablemente para consulta o análisis. |
| `soporte` | No | No | No | No | No | No | Rol de grupo, probablemente para tareas de soporte. |

![Roles](evidencias/roles.png)

**Identificación:**

- **Superusuarios:** `postgres`.
- **Usuarios que pueden iniciar sesión:** solo `postgres`.
- **Usuarios con CREATEROLE:** `postgres`.
- **Usuarios con CREATEDB:** `postgres`.
- **Roles utilizados por aplicaciones:** ninguno dedicado. La conexión de pgAdmin usa `postgres`.
- **Cuentas que podrían ser innecesarias:** `analista` y `soporte` no representan riesgo por sí mismos (no pueden iniciar sesión), pero hay que verificar a qué roles pertenecen y qué permisos tienen para confirmar que son necesarios.

**¿Por qué no debería utilizarse una cuenta SUPERUSER como cuenta normal de una aplicación?**
Porque un superusuario ignora todas las comprobaciones de permisos: puede leer y modificar cualquier dato, crear y borrar roles y bases de datos, cargar extensiones, y ejecutar `COPY ... PROGRAM` o leer archivos del servidor, lo que puede llevar a ejecutar comandos en el sistema operativo. Si la aplicación se compromete (por ejemplo, con una inyección SQL), el atacante obtiene control total del servidor y no solo de los datos de la aplicación. Además, un error de la aplicación podría borrar o alterar datos que no le corresponden.

### Complemento de la Actividad 8: membresías y permisos de los roles de grupo

**Membresías:** la consulta sobre `pg_auth_members` devolvió vacío. `analista` y `soporte` no tienen ningún miembro, por lo que actualmente no los usa ninguna cuenta.

**Permisos sobre tablas y vistas (base `laboratorios`):**

| Rol | Esquema | Objeto | Privilegio | Observación |
|---|---|---|---|---|
| `analista` | `analitica` | `clientes` (tabla) | SELECT | Acceso directo a la tabla base. Revisar si contiene datos sensibles. |
| `analista` | `public` | `v_analitica_clientes` (vista) | SELECT | Acceso mediante vista. Correcto. |
| `soporte` | `public` | `v_clientes_soporte` (vista) | SELECT | Acceso mediante vista, solo lectura. Correcto. |

**Conclusión:** los roles de grupo siguen un diseño de mínimo privilegio (solo lectura, y en el caso de `soporte` solo a través de una vista). Sin embargo, no están asignados a ninguna cuenta con `LOGIN`, así que en la práctica todo el trabajo se hace con `postgres`. El acceso directo de `analista` a `analitica.clientes` debe revisarse.


## Actividad 9: Separar cuentas administrativas y de aplicación

| Cuenta | Propósito | LOGIN | Privilegios | Origen permitido |
|---|---|---|---|---|
| `dba_lab` | Administración | Sí | Administrativos (`CREATEROLE`, `CREATEDB`), sin usarse para aplicaciones | `127.0.0.1`, `::1` |
| `app_lab` | Conexión del software | Sí | Mínimos: `CONNECT`, `USAGE` en el esquema y `SELECT/INSERT/UPDATE/DELETE` solo sobre las tablas necesarias | `127.0.0.1`, `::1` |
| `consulta_lab` | Consulta | Sí | Solo lectura (`SELECT`), por ejemplo mediante pertenencia a `analista` | `127.0.0.1`, `::1` |
| `postgres` | Cuenta de emergencia | Sí | Superusuario, reservada para mantenimiento | Solo local |

**¿Qué riesgo existe si la aplicación se conecta utilizando una cuenta administrativa?**
Cualquier vulnerabilidad de la aplicación se convierte en control total del servidor. Un atacante podría leer o borrar todas las bases, crear cuentas persistentes, cambiar contraseñas y, siendo superusuario, alcanzar el sistema operativo. También se pierde la trazabilidad (no se distingue qué hizo la aplicación y qué hizo el administrador) y se incumple el principio de mínimo privilegio.

## Actividad 13: Revisar exposición de red

**Dirección de escucha:** `0.0.0.0` (IPv4) y `[::]` (IPv6).

**Puerto:** `5432`.

**¿Está expuesto fuera de la interfaz necesaria?** **Sí.** El servicio solo necesita localhost, pero escucha en todas las interfaces. Que no haya conexiones externas activas no significa que no se puedan establecer: lo único que lo impide en este momento son las reglas de `pg_hba.conf` y del firewall, que aún no se han revisado.