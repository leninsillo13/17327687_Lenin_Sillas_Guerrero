# Actividad 5 — Verificar el estado de TLS en PostgreSQL

## Objetivo

Verificar la configuración de TLS del servidor PostgreSQL y comprobar si la sesión actual está protegida con TLS, identificando la versión del protocolo y el algoritmo de cifrado utilizados.

## Comando o procedimiento

**1. Configuración de TLS del servidor**

```sql
SHOW ssl;
SHOW ssl_min_protocol_version;
SHOW port;
SHOW listen_addresses;
```

**2. Datos de la conexión actual**

```sql
SELECT
    inet_client_addr(),
    inet_client_port();
```

**3. Verificación de TLS en la sesión actual**

```sql
SELECT
    ssl,
    version,
    cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
```

## Resultado obtenido

**`SHOW ssl;`**

```text
off
```

**`SHOW ssl_min_protocol_version;`**

```text
TLSv1.2
```

**`SHOW port;`**

```text
5432
```

**`SHOW listen_addresses;`**

```text
*
```

**`inet_client_addr()` e `inet_client_port()`:**

```text
"::1"	63517
```

**`pg_stat_ssl` (sesión actual):**

```text
false		
```

## Análisis

**1. ¿La conexión actual utiliza TLS?**
No. La columna `ssl` de `pg_stat_ssl` es `false`, y coincide con que el servidor tiene `ssl = off`. La sesión actual no está cifrada.

**2. ¿Qué versión de TLS se está utilizando?**
Ninguna. La columna `version` está vacía (`NULL`) porque no se negoció TLS en esta sesión. El valor `TLSv1.2` de `ssl_min_protocol_version` es solo la versión mínima que el servidor aceptaría si TLS estuviera habilitado; no indica que se esté usando.

**3. ¿Qué algoritmo de cifrado aparece?**
Ninguno. La columna `cipher` está vacía (`NULL`) por la misma razón: al no haber TLS, no se negoció ningún conjunto de cifrado.

**4. ¿Qué diferencia existe entre una conexión protegida con TLS y una conexión sin TLS?**
- **Con TLS:** la comunicación entre cliente y servidor viaja cifrada. Protege la confidencialidad (nadie en la red puede leer consultas, resultados o credenciales), la integridad (detecta modificaciones en tránsito) y, con certificados validados, la autenticidad del servidor (evita suplantación).
- **Sin TLS:** los datos viajan en texto claro, por lo que quien pueda capturar el tráfico puede leer consultas, datos y credenciales, o incluso alterarlos mediante ataques de intermediario (*man-in-the-middle*).

**Interpretación de la configuración del servidor**
- `ssl = off`: el servidor no tiene TLS habilitado, por lo que no puede ofrecer conexiones cifradas a ningún cliente.
- `ssl_min_protocol_version = TLSv1.2`: define la versión mínima de TLS que se aceptaría una vez habilitado; es una configuración adecuada porque TLS 1.0 y 1.1 se consideran inseguros.
- `port = 5432`: es el puerto por defecto de PostgreSQL.
- `listen_addresses = *`: el servidor acepta conexiones por todas sus interfaces de red, no solo localmente.
- `inet_client_addr() = ::1`: es la dirección de loopback IPv6 (localhost). La conexión se hizo por TCP desde la misma máquina, no desde la red. Por eso el tráfico no sale del equipo, pero aun así no está cifrado.

**Riesgo identificado**
La combinación `listen_addresses = *` con `ssl = off` es riesgosa fuera de un entorno de laboratorio: el servidor acepta conexiones desde cualquier interfaz y todas viajarían en texto claro. En el laboratorio el riesgo es bajo porque la conexión actual es local (`::1`).

## Conclusión

La sesión actual no utiliza TLS, ya que el servidor tiene `ssl = off` y `pg_stat_ssl` muestra `ssl = false` sin versión ni algoritmo de cifrado. Aunque los datos sensibles puedan estar protegidos dentro de la base de datos (hash o cifrado), viajarían sin protección por la red si la conexión no fuera local. En un entorno real se debe habilitar TLS (`ssl = on`) con certificados válidos, mantener una versión mínima segura (`TLSv1.2` o superior), limitar `listen_addresses` a las interfaces necesarias y exigir conexiones cifradas.

#  Actividad 6 — Conexión mediante psql

## Objetivo

Conectarse a PostgreSQL desde `psql` indicando explícitamente el modo TLS (`sslmode`), verificar si la sesión resultante está cifrada y comprender las diferencias entre los modos `disable`, `prefer`, `require`, `verify-ca` y `verify-full`.

## Comando o procedimiento

**1. Conexión solicitando TLS obligatorio (`sslmode=require`)**

Sustituir `SERVIDOR`, `TU_BASE` y `TU_USUARIO` por los valores de mi entorno:

```bash
psql "host=SERVIDOR port=5432 dbname=TU_BASE user=TU_USUARIO sslmode=require"
```

**2. Conexión de comparación con `sslmode=prefer`** (si el paso anterior fue rechazado)

```bash
psql "host=SERVIDOR port=5432 dbname=TU_BASE user=TU_USUARIO sslmode=prefer"
```

**3. Verificación de TLS en la sesión (una vez conectado)**

```sql
SELECT
    ssl,
    version,
    cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
```

## Resultado obtenido

**Valores usados en la conexión (sin contraseña):**

```text
host= localhost
port= 5432
dbname= laboratorios
user= postgres
```

**Intento con `sslmode=require`:**

```text
falló la conexión al servidor en «localhost» (::1), puerto 5432: el servidor no soporta SSL, pero SSL es requerida
Se ha mantenido la conexión anterior
```

**Intento con `sslmode=prefer`:**

```text
Ahora está conectado a la base de datos «laboratorios» con el usuario «postgres».
```

**`pg_stat_ssl` (sesión de `psql`):**

```text
 ssl | version | cipher
-----+---------+--------
 f   |         |
(1 fila)
```

## Análisis

**Resultado de la conexión con `sslmode=require`**
El modo `require` exige que la conexión use TLS: si el servidor no lo ofrece, `psql` rechaza la conexión en lugar de continuar sin cifrar. Como en la Actividad 5 el servidor tenía `ssl = off`, el resultado esperado es un error similar a:

```text
psql: error: connection to server at "..." failed: server does not support SSL, but SSL was required
```

Esto es un comportamiento correcto: `require` evita que la sesión caiga silenciosamente a texto claro.

**Resultado con `sslmode=prefer`**
`prefer` intenta TLS primero, pero si el servidor no lo soporta continúa sin cifrar. Por eso la conexión se establece, y `pg_stat_ssl` muestra `ssl = false` (sin versión ni algoritmo), igual que en la Actividad 5.

**¿Qué demuestra esto?**
El cliente puede solicitar TLS, pero solo se logra si el servidor lo tiene habilitado. La protección depende de ambos lados: el servidor debe tener `ssl = on` con certificado, y el cliente debe usar un `sslmode` que lo exija. Un modo permisivo como `prefer` puede dar una falsa sensación de seguridad.

**Comprender `sslmode`**

| Modo | ¿Usa TLS? | ¿Verifica certificado? | ¿Verifica nombre del servidor? | Comentario |
|---|---|---|---|---|
| `disable` | No | No | No | Nunca usa TLS; todo viaja en texto claro. |
| `prefer` | Si el servidor lo ofrece | No | No | Si no hay TLS, continúa sin cifrar (valor por defecto). |
| `require` | Sí, obligatorio | No | No | Cifra, pero no confirma la identidad del servidor; vulnerable a un servidor suplantado. |
| `verify-ca` | Sí, obligatorio | Sí, contra una CA de confianza | No | Garantiza que el certificado lo emitió una CA confiable. |
| `verify-full` | Sí, obligatorio | Sí, contra una CA de confianza | Sí | Además confirma que el nombre del servidor coincide con el certificado. |

**Por qué `verify-full` es el modelo a comprender**
Con `require` el tráfico va cifrado, pero un atacante que se haga pasar por el servidor (*man-in-the-middle*) también puede presentar un certificado propio y la conexión seguiría funcionando. `verify-ca` verifica que el certificado venga de una autoridad confiable, pero un certificado válido emitido para otro servidor seguiría aceptándose. `verify-full` cierra esa brecha al comprobar también que el nombre al que me conecto coincide con el del certificado, por lo que protege la confidencialidad y la identidad del servidor. Es el modo adecuado cuando se requiere una validación fuerte.

## Conclusión

La conexión con `sslmode=require` solo funciona si el servidor soporta TLS; con `ssl = off` es rechazada, lo cual evita enviar datos sin cifrar por error. Con `sslmode=prefer` la conexión se establece sin TLS, como confirma `pg_stat_ssl` (`ssl = false`). Los modos `require`, `verify-ca` y `verify-full` ofrecen niveles crecientes de garantía: cifrado, verificación de la autoridad certificadora y verificación de la identidad del servidor. En un entorno real se debe habilitar TLS en el servidor y usar `verify-full` para protegerse tanto de la lectura del tráfico como de la suplantación del servidor.