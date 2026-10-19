# LAB-02 — Cifrado, credenciales y comunicaciones seguras

## Informe final

## 1. Introducción

Una base de datos puede tener usuarios, roles y permisos bien configurados y, aun así, exponer información sensible si los datos se almacenan o se transmiten sin protección. En este laboratorio se abordó ese problema: qué ocurre cuando las contraseñas y otros datos sensibles se guardan en texto claro, cómo protegerlos con las funciones de `pgcrypto`, qué papel cumple TLS en la comunicación entre cliente y servidor y por qué la gestión de las claves criptográficas es tan importante como el algoritmo que se utiliza.

## 2. Protección de credenciales

**Texto claro.** La contraseña se guarda tal cual (`Password123`). Cualquier persona con acceso de lectura a la tabla, a un respaldo o a un volcado la ve de inmediato.

**Hash.** Es una transformación de una sola vía: a partir del resultado no se puede obtener la contraseña original. Se calculó con `crypt()` y `gen_salt('bf')` (bcrypt). Cada ejecución produjo un resultado distinto para la misma contraseña, porque `gen_salt()` genera una sal aleatoria. Para verificar una contraseña no se recupera la original: se recalcula el hash con la sal guardada y se compara con el almacenado. Dio `true` con la contraseña correcta y `false` con la incorrecta.

**Cifrado.** Es una transformación reversible que depende de una clave: con la clave correcta se recupera el dato original (`pgp_sym_encrypt()` y `pgp_sym_decrypt()`). Sirve para datos que la aplicación necesita volver a leer, pero no es adecuado para contraseñas, porque si se expone la clave se pueden recuperar todas.

| Mecanismo | ¿Reversible? | Necesita clave | Uso adecuado |
|---|---|---|---|
| Texto claro | No aplica | No | Ninguno para datos sensibles |
| Hash con sal | No | No | Contraseñas |
| Cifrado simétrico | Sí | Sí | Datos que deben recuperarse (RFC) |

## 3. Protección de datos sensibles

Se protegió el **RFC** de un cliente almacenándolo en una columna `BYTEA` cifrada con `pgp_sym_encrypt()`. Se eligió porque es un dato personal sensible que, si se filtra, puede usarse para suplantar la identidad o cometer fraude. Se utilizó cifrado reversible y no hash porque la aplicación necesita poder leerlo de nuevo.

Al consultar la tabla, el RFC ya no aparece en texto claro, solo un valor binario. Se recuperó con `pgp_sym_decrypt()` usando la clave correcta, y con una clave incorrecta PostgreSQL devolvió un error (`Wrong key or corrupt data`) sin revelar ninguna parte del dato.

Usar la clave directamente en la consulta fue únicamente para fines demostrativos, ya que, como se explica en la sección 5, es una mala práctica.

## 4. TLS

**Qué problema resuelve.** TLS protege la información mientras viaja entre cliente y servidor. Garantiza confidencialidad (nadie en la red puede leer consultas, resultados o credenciales), integridad (detecta alteraciones) y, con certificados validados, autenticidad del servidor, lo que evita que alguien se haga pasar por él (*man-in-the-middle*).

**Qué se verificó en PostgreSQL.**

| Verificación | Resultado |
|---|---|
| `SHOW ssl;` | `off` |
| `SHOW ssl_min_protocol_version;` | `TLSv1.2` |
| `SHOW port;` | `5432` |
| `SHOW listen_addresses;` | `*` |
| `inet_client_addr()` / `inet_client_port()` | `::1` / `63517` |
| `pg_stat_ssl` (sesión actual) | `ssl = false`, sin versión ni algoritmo de cifrado |

El servidor tiene TLS deshabilitado, por lo que la sesión actual no está cifrada. La versión mínima `TLSv1.2` solo indica lo que se aceptaría si TLS estuviera habilitado. La conexión se realizó desde `::1` (loopback IPv6), es decir, localmente, por lo que el tráfico no sale del equipo, aunque tampoco está cifrado.

Con `psql` se estudiaron los modos `sslmode`: `disable`, `prefer`, `require`, `verify-ca` y `verify-full`. Como el servidor no tiene TLS, `sslmode=require` fue rechazado, mientras que `sslmode=prefer` conectó sin cifrar. El modo `verify-full` es el que debe usarse en un entorno real, porque además de cifrar valida el certificado y que el nombre del servidor coincida con él.

## 5. Gestión de claves

Las claves no deben almacenarse junto con los scripts porque cualquier lugar donde viva el código se convierte en un punto de fuga: repositorios Git, historial de commits, archivos de configuración, registros de ejecución, capturas de pantalla, respaldos y documentación. Quien obtenga el script y los datos cifrados puede descifrarlos y el cifrado deja de aportar protección.

En el laboratorio se creó un archivo temporal `sql/ejemplo-mala-practica.sql` con una clave ficticia (`CLAVE-DE-PRUEBA`) para analizar el riesgo, y se eliminó para que no formara parte de la entrega. En un entorno real, la clave debe almacenarse en un gestor de secretos o KMS, separada de los datos y del código, con acceso restringido, rotación y registro de uso. Se elaboró además una política mínima de ocho reglas que cubre generación, almacenamiento, acceso, rotación, respaldo, revocación, exposición accidental y eliminación.

## 6. Resultados

- Con la tabla `usuarios_insegura`, la contraseña se ve directamente en texto claro.
- Con `crypt()` y `gen_salt('bf')`, dos ejecuciones con la misma contraseña produjeron hashes distintos por la sal aleatoria. No es cifrado reversible.
- En `usuarios_segura` solo se almacena el hash. La verificación devolvió `true` con la contraseña correcta y `false` con la incorrecta.
- El RFC se almacenó cifrado en `clientes_protegidos`, se recuperó con la clave correcta y falló con una clave incorrecta.
- El servidor tiene `ssl = off` y la sesión actual no usa TLS. La combinación `listen_addresses = *` con TLS deshabilitado sería riesgosa fuera de un laboratorio.
- Se comprendió la diferencia entre `require`, `verify-ca` y `verify-full`.
- Se identificó que las claves en archivos SQL son el problema más crítico del escenario de la actividad 8, y se redactó una política mínima de gestión de claves.

## 7. Problemas encontrados

- **Uso de SQL Shell (psql).** Al conectarme con SQL Shell, el programa pide los datos uno por uno (servidor, base, puerto, usuario y contraseña). Me confundí con el orden de las preguntas y escribí la contraseña antes de tiempo. Se resolvió aceptando los valores predeterminados con Enter y escribiendo la contraseña solo en el paso `Password for user`.
- **Cambio de `sslmode` desde SQL Shell.** SQL Shell no permite indicar `sslmode` en sus preguntas, por lo que se utilizó el comando `\c` con una cadena de conexión para probar los distintos modos.
- **TLS no habilitado.** El servidor tiene `ssl = off`, por lo que no fue posible observar una sesión cifrada con versión de TLS y algoritmo. El resultado se documentó tal cual y se analizó por qué ocurre.

## 8. Conclusiones

Aprendí que proteger una base de datos no se limita a administrar usuarios y permisos: los datos deben protegerse también en reposo, en tránsito y en la gestión de sus claves. Las contraseñas deben guardarse con hash con sal, los datos que deben recuperarse con cifrado reversible, y las comunicaciones deben ir cifradas con TLS validando la identidad del servidor. Además, el cifrado solo es tan fuerte como la protección de su clave.

En un entorno productivo aplicaría las siguientes medidas:

- Almacenar las contraseñas con un algoritmo diseñado para ello (Argon2id, scrypt o bcrypt) mediante las funciones del framework, sin implementar un algoritmo propio.
- Cifrar los datos sensibles como el RFC y la información financiera, y limitar quién puede leerlos.
- Habilitar TLS (`ssl = on`) con certificados válidos, mantener una versión mínima segura (`TLSv1.2` o superior) y exigir `sslmode=verify-full` en los clientes.
- Limitar `listen_addresses` a las interfaces necesarias.
- Guardar las claves en un gestor de secretos o KMS, con rotación, acceso restringido y registro de uso, y nunca en scripts ni en el repositorio.
- Cifrar los respaldos y controlar su acceso.
- Utilizar herramientas de detección de secretos en los repositorios.

## Preguntas de reflexión

**1. ¿Por qué una contraseña no debe almacenarse como texto claro?**
Porque cualquier persona con acceso de lectura a la tabla, a un respaldo o a un volcado puede leerla y usarla de inmediato. Una filtración de la base de datos se convertiría directamente en una filtración de credenciales, y como muchas personas reutilizan contraseñas, el daño se extendería a otros servicios.

**2. ¿Por qué un hash no es equivalente a un cifrado?**
El cifrado es reversible: con la clave correcta se recupera el dato original. El hash es de una sola vía: no tiene clave ni operación inversa, y solo permite comprobar si una contraseña candidata produce el mismo resultado. Por eso el hash es adecuado para contraseñas, que solo necesitan verificarse, y el cifrado para datos que deben volver a leerse.

**3. ¿Por qué el cifrado de una columna no sustituye al control de acceso?**
Porque cumplen funciones distintas. El control de acceso decide quién puede consultar, modificar o administrar los datos. El cifrado protege el contenido si alguien lo obtiene por otra vía (un respaldo, un archivo del disco, una filtración). Sin control de acceso, cualquier usuario con permisos amplios podría ejecutar el descifrado si conoce o puede obtener la clave, y sin cifrado, los permisos no protegen los datos fuera de la base. Se necesitan ambos.

**4. ¿Por qué TLS no sustituye a los mecanismos de autorización de PostgreSQL?**
TLS protege el canal de comunicación (confidencialidad, integridad y autenticidad del servidor), pero no decide qué puede hacer cada usuario una vez conectado. Una conexión cifrada puede ser de un usuario con permisos excesivos o de uno que no debería acceder a ciertos datos. La autorización (roles y permisos) controla qué acciones y datos están permitidos, y TLS evita que el tráfico sea interceptado o alterado.

**5. ¿Qué ocurriría si una organización pierde una clave utilizada para cifrar información?**
Los datos cifrados con esa clave serían irrecuperables, porque sin la clave correcta no se pueden descifrar (como se vio al probar con una clave incorrecta). Por eso deben existir respaldos protegidos de las claves y un procedimiento probado de recuperación.

**6. ¿Qué ocurriría si una clave criptográfica se publica accidentalmente en GitLab?**
Debe considerarse comprometida. Cualquier persona con acceso al repositorio, a sus clones o a sus forks puede leerla, y si además obtiene los datos cifrados, puede descifrarlos. Aunque el archivo se borre después, la clave permanece en el historial de commits. Se debe revocar y rotar de inmediato, volver a cifrar los datos con una clave nueva, revisar los accesos realizados y reportar el incidente.

**7. ¿Por qué un repositorio privado no debe considerarse un almacén de secretos?**
Un repositorio privado reduce la exposición, pero no convierte un secreto en información apropiada para almacenar dentro del código. Siguen teniendo acceso todas las personas con permisos sobre él, sus clones, forks y respaldos, los permisos pueden cambiar o comprometerse, y el secreto queda permanente en el historial. Los secretos deben guardarse en un gestor de secretos o en variables protegidas.

**8. ¿Qué diferencia existe entre proteger información almacenada y proteger información durante su transmisión?**
Proteger información almacenada (en reposo) busca que una filtración de la base, del disco o de un respaldo no exponga los datos, y se logra con hash y cifrado de datos. Proteger información en tránsito busca que nadie pueda leer o alterar los datos mientras viajan entre cliente y servidor, y se logra con TLS. Son protecciones complementarias: una no sustituye a la otra.

**9. ¿Por qué la gestión de claves es tan importante como el algoritmo criptográfico?**
Porque la seguridad del cifrado depende de que la clave permanezca secreta. Un algoritmo robusto no protege nada si la clave está en un script, se pierde o la conoce demasiada gente. Generación, almacenamiento, acceso, rotación, respaldo, revocación y eliminación determinan en la práctica si el cifrado realmente protege los datos.

**10. ¿Qué mecanismo adicional implementarías en una organización para proteger los respaldos de las bases de datos?**
Cifraría los respaldos y el medio donde se almacenan, usando una clave gestionada por separado en un KMS o gestor de secretos. Además restringiría el acceso por mínimo privilegio, mantendría copias en ubicaciones controladas, registraría los accesos y probaría periódicamente la restauración, incluyendo la recuperación de la clave.