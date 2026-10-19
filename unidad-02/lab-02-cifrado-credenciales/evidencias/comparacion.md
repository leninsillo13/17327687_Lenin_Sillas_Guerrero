# Actividad 7 — Comparar protección en reposo y protección en tránsito

## Objetivo

Distinguir entre la protección de datos en reposo (almacenados) y en tránsito (viajando por la red), y asociar a cada situación el mecanismo criptográfico apropiado según lo que se necesita proteger.

## Comando o procedimiento

Análisis conceptual de cinco situaciones usando lo practicado en las actividades anteriores (`crypt()`, `pgp_sym_encrypt()`, TLS y gestión de claves). No requiere ejecutar comandos nuevos.

## Resultado obtenido

| Situación | Mecanismo apropiado | ¿Qué protege? |
|---|---|---|
| Contraseña de usuario | Hash con sal usando un algoritmo diseñado para contraseñas (por ejemplo, bcrypt con `crypt()` y `gen_salt('bf')`; en aplicaciones reales, Argon2id, scrypt o bcrypt según el framework) | Protege la credencial en reposo. Al ser de una sola vía, una filtración de la base no revela la contraseña original, y la sal evita que contraseñas iguales tengan el mismo hash. |
| RFC almacenado en una tabla | Cifrado simétrico reversible (`pgp_sym_encrypt()` / `pgp_sym_decrypt()`) con una clave gestionada fuera de la consulta | Protege la confidencialidad del dato en reposo, pero permite recuperarlo cuando la aplicación lo necesita. |
| Consulta enviada desde un cliente al servidor | TLS (con `sslmode=verify-full` en entornos reales) | Protege la información en tránsito: confidencialidad (nadie puede leer consultas, resultados ni credenciales), integridad (detecta alteraciones) y autenticidad del servidor. |
| Respaldo de una base de datos | Cifrado del archivo de respaldo (y del medio de almacenamiento) con una clave gestionada por separado, además de controlar el acceso | Protege los datos en reposo fuera de la base: si el respaldo se pierde o se roba, su contenido no se puede leer sin la clave. |
| Clave criptográfica | Gestor de secretos o KMS, con control de acceso, rotación y almacenamiento separado de los datos y del código | Protege la propia clave: si se expone, el cifrado que depende de ella deja de proteger los datos. |

## Análisis

**Protección en reposo vs. en tránsito**
- **En reposo:** protege los datos almacenados (tablas, archivos, respaldos). Se logra con hash o cifrado de datos. Su objetivo es que una filtración de la base o del disco no exponga la información.
- **En tránsito:** protege los datos mientras viajan entre cliente y servidor. Se logra con TLS. Su objetivo es que nadie que observe o modifique el tráfico pueda leer o alterar la información.
- Son protecciones complementarias, no sustitutas. Como se vio en la Actividad 5, una base puede tener datos cifrados en reposo y aun así enviar las consultas sin TLS (`ssl = off`), y a la inversa.

**Por qué se elige cada mecanismo**
- **Contraseña:** nunca necesita recuperarse, solo verificarse. Por eso se usa hash y no cifrado reversible. Cifrarla con una clave fija sería una mala práctica, porque quien obtenga la clave recupera todas las contraseñas.
- **RFC:** la aplicación debe poder leerlo de nuevo, así que se necesita cifrado reversible. Un hash no serviría porque no permite recuperar el valor.
- **Consulta del cliente al servidor:** se protege el canal, no el dato almacenado. Aquí aplica TLS, y `verify-full` añade verificación de la identidad del servidor para evitar suplantación.
- **Respaldo:** es una copia de los datos fuera del control normal de la base de datos. Aunque algunas columnas ya estén cifradas, el respaldo completo debe cifrarse y su acceso restringirse, porque contiene el resto de la información.
- **Clave:** es el secreto del que depende el cifrado. Debe estar separada de los datos cifrados y del código (Actividad 3), con acceso restringido y rotación periódica.

**Dependencia entre mecanismos**
El cifrado del RFC y del respaldo es tan fuerte como la protección de la clave. Por eso la gestión de claves es una protección en sí misma y no un detalle de implementación.

## Conclusión

No existe un único mecanismo que sirva para todo: la elección depende de qué se protege y de si el dato debe poder recuperarse. Las contraseñas se protegen con hash con sal, los datos que deben leerse de nuevo (como el RFC) con cifrado reversible, la comunicación con TLS, los respaldos con cifrado del archivo y las claves con un gestor de secretos. La protección en reposo y la protección en tránsito se complementan, y todas ellas dependen de una correcta gestión de las claves.