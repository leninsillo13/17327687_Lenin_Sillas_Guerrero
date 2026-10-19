# Actividad 1 — Protección de credenciales

## Objetivo

Demostrar el riesgo de almacenar contraseñas en texto claro y comprobar cómo una representación no reversible (hash con sal) protege las credenciales, y cómo se verifica una contraseña sin necesidad de recuperarla.

## Comando o procedimiento

**1. Tabla insegura (texto claro)**

```sql
CREATE TABLE usuarios_insegura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL
);

INSERT INTO usuarios_insegura (usuario, password)
VALUES ('juan', 'Password123');

SELECT * FROM usuarios_insegura;
```

**2. Generación de hashes con `pgcrypto` (ejecutada dos veces)**

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

SELECT crypt('Password123', gen_salt('bf'));
SELECT crypt('Password123', gen_salt('bf'));
```

**3. Tabla con credenciales protegidas**

```sql
CREATE TABLE usuarios_segura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL
);

INSERT INTO usuarios_segura (usuario, password_hash)
VALUES ('juan', crypt('Password123', gen_salt('bf')));

SELECT * FROM usuarios_segura;
```

**4. Verificación de contraseña**

```sql
-- Contraseña correcta
SELECT usuario,
       password_hash = crypt('Password123', password_hash) AS contraseña_correcta
FROM usuarios_segura
WHERE usuario = 'juan';

-- Contraseña incorrecta
SELECT usuario,
       password_hash = crypt('OtraPassword', password_hash) AS contraseña_correcta
FROM usuarios_segura
WHERE usuario = 'juan';
```

## Resultado obtenido

**Tabla `usuarios_insegura`:**

```
1	"juan"	"Password123"
```


**Dos ejecuciones de `crypt()` con `gen_salt('bf')`:**

```
$2a$06$BeFvsIHDSp/1hVkiMRrv2u4tbIlFxg5QZ4Z0zecyibNvggFCV2YX2
```

```
$2a$06$DoIFkYr7BYfXdbcQPJXF8uxi9qiUDLgocQ56c6WWaZPWP64I96Yai
```


**Tabla `usuarios_segura`:**

```
1	"juan"	"$2a$06$k0ij4qbuTtiQiVbgjJgAXOiyEntbbbwjMnar/qRaJljupLfpKhbkm"
```

**Verificación:**

Contraseña correcta:

```
"juan"	true
```

Contraseña incorrecta:

```
"juan"	false
```


## Análisis

**¿Qué ocurriría si una persona obtiene acceso de lectura a `usuarios_insegura`?**
Vería directamente la contraseña de cada usuario en texto claro (por ejemplo, `Password123`). Podría suplantar a los usuarios, probar esas contraseñas en otros servicios donde se reutilizan, y una filtración de la base de datos se convertiría automáticamente en una filtración de credenciales.

**¿Son iguales los dos hashes?**
No. Aunque la contraseña es la misma, los resultados son distintos.

**¿Por qué no son iguales?**
Porque cada llamada a `gen_salt('bf')` genera una sal aleatoria diferente, que se mezcla con la contraseña antes de calcular el hash. Una sal distinta produce un hash distinto.

**¿Qué función cumple `gen_salt()`?**
Genera la sal aleatoria junto con la configuración del algoritmo (`bf` = bcrypt/Blowfish y su costo). Hace que contraseñas iguales tengan hashes diferentes y dificulta los ataques con tablas precalculadas (*rainbow tables*).

**¿Qué función cumple `crypt()`?**
Calcula el hash de una contraseña usando una sal y un algoritmo. El resultado incluye el algoritmo, el costo, la sal y el hash, por lo que se puede guardar en una sola columna y usar después para verificar contraseñas.

**¿Esto es cifrado reversible?**
No. Es un hash de una sola vía: no existe una operación para obtener la contraseña original a partir del resultado.

**¿Qué resultado se obtuvo con la contraseña correcta?**
`true` (`t`): al recalcular el hash con la sal almacenada, coincide con el hash guardado.

**¿Qué resultado se obtuvo con la contraseña incorrecta?**
`false` (`f`): el hash calculado no coincide con el almacenado.

**¿Por qué no es necesario recuperar la contraseña original?**
Porque la verificación compara hashes, no contraseñas. Se toma la sal guardada, se calcula el hash de la contraseña ingresada y se compara con el almacenado. Así se confirma que el usuario la conoce sin que el sistema tenga que guardarla ni recuperarla.

**¿Por qué un hash no debe confundirse con cifrado?**
El cifrado es reversible: con la clave correcta se recupera el dato original. El hash es de una sola vía y no tiene clave ni operación inversa. Para contraseñas solo se necesita verificarlas, no recuperarlas, por lo que el hash es lo adecuado.

**Consideración para aplicaciones reales**
`pgcrypto` se usó con fines didácticos. En una aplicación real se debe elegir el algoritmo según las recomendaciones actuales de seguridad y las capacidades del framework. No se debe implementar un algoritmo de hash propio, guardar contraseñas en texto claro, ni cifrarlas con una clave fija como si fueran datos recuperables.

## Conclusión

Guardar contraseñas en texto claro convierte cualquier filtración de la base de datos en un compromiso inmediato de las cuentas. Usar un hash con sal aleatoria (`crypt()` + `gen_salt()`) evita almacenar la contraseña original, produce hashes distintos para contraseñas iguales y permite verificar credenciales sin poder revertirlas. Por eso, en sistemas reales las contraseñas deben protegerse con algoritmos de hash de contraseñas vigentes y no con texto claro ni cifrado reversible.