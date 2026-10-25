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

## Actividad 13: Revisar exposición de red

**Dirección de escucha:** `0.0.0.0` (IPv4) y `[::]` (IPv6).

**Puerto:** `5432`.

**¿Está expuesto fuera de la interfaz necesaria?** **Sí.** El servicio solo necesita localhost, pero escucha en todas las interfaces. Que no haya conexiones externas activas no significa que no se puedan establecer: lo único que lo impide en este momento son las reglas de `pg_hba.conf` y del firewall, que aún no se han revisado.