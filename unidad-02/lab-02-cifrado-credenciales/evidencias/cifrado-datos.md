# Actividad 2 — Cifrado de información sensible

## Objetivo

Proteger un dato sensible (el RFC) mediante cifrado simétrico con `pgcrypto`, comprobar que no se muestra en texto claro al consultar la tabla, recuperarlo con la clave correcta y analizar las diferencias entre hash (`crypt()`) y cifrado reversible (`pgp_sym_encrypt()`).

## Comando o procedimiento

**1. Crear la tabla de demostración**

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE clientes_protegidos (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    rfc_cifrado BYTEA NOT NULL
);
```

**2. Insertar un registro con cifrado simétrico**

```sql
INSERT INTO clientes_protegidos (nombre, rfc_cifrado)
VALUES (
    'Ana López',
    pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA')
);
```

**3. Consultar la tabla**

```sql
SELECT * FROM clientes_protegidos;
```

**4. Recuperar el dato con la clave correcta**

```sql
SELECT
    id,
    nombre,
    pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA') AS rfc
FROM clientes_protegidos;
```

**5. Probar con una clave incorrecta**

```sql
SELECT
    id,
    nombre,
    pgp_sym_decrypt(rfc_cifrado, 'CLAVE-INCORRECTA') AS rfc
FROM clientes_protegidos;
```

## Resultado obtenido

**Consulta de la tabla (`SELECT * FROM clientes_protegidos`):**

```text
1	"Ana López"	"binary data"
```

**Recuperación con la clave correcta:**

```text
1	"Ana López"	"LOPA900101ABC"
```

**Recuperación con la clave incorrecta (mensaje de error):**

```text
ERROR:  Wrong key or corrupt data 

SQL state: 39000
```

## Análisis

**1. ¿Qué diferencia existe entre `crypt()` y `pgp_sym_encrypt()`?**
`crypt()` genera un hash de una sola vía: transforma la contraseña en un valor del que no se puede obtener el original, y se usa para verificar contraseñas. `pgp_sym_encrypt()` realiza un cifrado simétrico reversible: transforma el dato usando una clave y permite recuperarlo después con `pgp_sym_decrypt()` y esa misma clave.

**2. ¿Cuál de los dos mecanismos permite recuperar el dato original?**
Solo `pgp_sym_encrypt()`, mediante `pgp_sym_decrypt()` con la clave correcta. Con `crypt()` no se puede recuperar el dato original, únicamente comprobar si una contraseña candidata coincide con el hash.

**3. ¿Qué ocurre si se utiliza una clave incorrecta?**
El dato no se puede descifrar y PostgreSQL devuelve un error (`Wrong key or corrupt data`). No se obtiene el RFC ni una versión parcial de él.

**4. ¿Qué problema de seguridad representa colocar la clave directamente en una consulta?**
La clave queda expuesta en lugares donde puede ser leída por terceros:
- El historial de comandos del cliente (`psql`, pgAdmin) y el código fuente o scripts.
- Los logs del servidor y herramientas de monitoreo como `pg_stat_statements` o `pg_stat_activity`.
- Los respaldos y repositorios donde se guarden esos scripts.

Quien obtenga la clave junto con la base de datos puede descifrar todos los datos, y el cifrado deja de aportar protección. En una aplicación real la clave debe gestionarse fuera de la base de datos (variables de entorno protegidas, gestor de secretos o KMS), con acceso restringido y rotación periódica, y nunca escribirse en consultas ni en el código.

## Conclusión

El cifrado simétrico con `pgp_sym_encrypt()` permite proteger datos sensibles que sí necesitan recuperarse, como el RFC, ya que al consultar la tabla solo se ve un valor binario ilegible. Se diferencia del hash de `crypt()` en que es reversible, lo cual lo hace adecuado para datos que la aplicación debe volver a leer, pero no para contraseñas. Su seguridad depende totalmente de la clave, por lo que escribirla directamente en las consultas es una mala práctica: debe almacenarse y gestionarse de forma separada y segura.