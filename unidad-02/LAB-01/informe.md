# LAB-01 — Protección y privacidad de datos

## Actividad 1 — Clasificación de los datos

| Campo | ¿Identifica directamente? | ¿Puede contribuir a identificar? | ¿Requiere protección? | Justificación |
|---|---|---|---|---|
| `id` | Sí, si está vinculado a una persona | Sí | Sí | Permite distinguir un registro y relacionarlo con una persona si se conoce su correspondencia. |
| `nombre` | Sí | Sí | Sí | Permite reconocer o identificar a una persona, especialmente si incluye apellidos. |
| `correo` | Sí | Sí | Sí | Puede identificar directamente a una persona y permite contactarla. |
| `telefono` | Sí | Sí | Sí | Puede asociarse con una persona y utilizarse para comunicarse con ella. |
| `rfc` | Sí | Sí | Sí | Es un identificador fiscal que permite relacionar información con un contribuyente. |
| `edad` | No | Sí | Sí | Por sí sola normalmente no identifica, pero combinada con otros datos puede ayudar a reconocer a alguien. |
| `ciudad` | No | Sí | Sí | Indica la ubicación general de una persona y puede reducir el grupo de personas posibles. |
| `codigo_postal` | No | Sí | Sí | Permite delimitar una zona geográfica y facilitar la identificación al combinarse con otros campos. |
| `fecha_alta` | No | Sí | Sí | Puede relacionarse con registros, actividades o fechas específicas de una persona. |


### 1. ¿Qué campos identifican directamente a una persona?

Los campos que pueden identificar directamente a una persona son `nombre`, `correo`, `telefono` y `rfc`. El campo `id` también puede hacerlo cuando está asociado con una persona específica dentro de una base de datos.

### 2. ¿Qué campos no identifican por sí solos pero podrían contribuir a hacerlo?

Los campos `edad`, `ciudad`, `codigo_postal` y `fecha_alta` generalmente no identifican por sí solos a una persona, pero pueden facilitar su identificación cuando se combinan con otros datos.

### 3. ¿Qué combinación de campos podría incrementar el riesgo de reidentificación?

Una combinación como `edad`, `ciudad`, `codigo_postal` y `fecha_alta` puede incrementar el riesgo de reidentificación, ya que permite reducir el número de personas que coinciden con esas características. Si además se agrega el nombre, el correo o el RFC, la identificación puede resultar mucho más sencilla.

### 4. ¿Todos los datos que deben protegerse son necesariamente datos personales sensibles desde el punto de vista jurídico?

No. No todos los datos que requieren protección son considerados datos personales sensibles desde el punto de vista jurídico. Los datos personales son aquellos que permiten identificar o hacer identificable a una persona, mientras que los datos personales sensibles son una categoría específica que incluye información relacionada con la salud, el origen racial o étnico, las creencias religiosas y otros aspectos íntimos cuya utilización indebida puede generar discriminación o un riesgo grave para la persona.

Por lo tanto, datos como el nombre, el correo electrónico, el teléfono y el RFC deben protegerse, aunque no necesariamente se clasifiquen como datos personales sensibles.


## Actividad 2 — Enmascaramiento (masking)

### 1. ¿Qué información continúa existiendo en la tabla original?

Todos los datos completos y sin modificar: correo, teléfono y RFC (además de `id`, `nombre` y cualquier otra columna). El enmascaramiento no altera ni borra nada; solo cambia lo que se muestra a través de la vista `v_clientes_soporte`.

### 2. ¿Qué información puede visualizar el usuario `soporte`?

Solo lo que devuelve la vista:

- `id` y `nombre` completos.
- **Correo parcial:** las 2 primeras letras, `*****` y el dominio desde la `@` (ej. `ju*****@gmail.com`).
- **Teléfono parcial:** `******` más los últimos 4 dígitos.
- **RFC parcial:** `*********` más los últimos 4 caracteres.

Con `GRANT USAGE` sobre el esquema, `GRANT SELECT` sobre la vista y el `REVOKE ALL` sobre `clientes`, no puede consultar la tabla original.

### 3. ¿Por qué no es suficiente ocultar los datos únicamente en la aplicación?

Porque la protección en la aplicación depende de que todos accedan por ella. Si alguien se conecta directamente a la base de datos (con un cliente SQL, un script o credenciales filtradas), puede saltarse esa capa y leer los datos reales. Además, un error o una modificación en el código de la aplicación podría exponer la información. La seguridad debe aplicarse en la propia base de datos (roles, permisos y vistas), que es donde residen los datos y donde se hace cumplir el control de acceso sin importar por dónde se entre.

### 4. ¿Qué ocurriría si `soporte` tuviera acceso directo a `clientes`?

Podría ejecutar `SELECT * FROM clientes;` y ver los correos, teléfonos y RFC completos, haciendo inútil el enmascaramiento de la vista. Esto expondría datos personales sensibles, incumpliendo el principio de mínimo privilegio y poniendo en riesgo la confidencialidad (y el cumplimiento de normativas de protección de datos personales, como la LFPDPPP en México).

## Actividad 4 — Separación de funciones

**1. ¿Qué ocurriría si `analista` pudiera consultar también `pii.mapa_cliente`?**

Podría hacer un `JOIN` entre `analitica.clientes` y `pii.mapa_cliente` y reidentificar a cada persona, es decir, asociar cada token con su identidad real. La seudonimización dejaría de proteger algo, porque el mismo usuario tendría los datos seudonimizados y la "llave" para revertirlos. El riesgo de exposición de datos personales (PII) volvería a ser prácticamente igual que si trabajara directamente con `public.clientes`.

**2. ¿Qué principio de seguridad se está aplicando al separar ambos accesos?**

Se aplican dos principios complementarios:

- **Separación de funciones (separation of duties):** quien analiza los datos no es quien custodia el mapa de reidentificación.
- **Mínimo privilegio (least privilege):** `analista` solo recibe los permisos estrictamente necesarios (`USAGE` sobre el esquema `analitica` y `SELECT` sobre `analitica.clientes`).

También se relaciona con el principio de **minimización de datos**, ya que el analista solo ve lo que necesita para su trabajo.

**3. ¿Por qué la seudonimización no equivale a anonimización?**

Porque en la seudonimización la identidad **puede recuperarse** si se dispone de información adicional (el mapa, una clave o los datos originales). Los datos siguen siendo datos personales y están sujetos a la normativa de protección de datos (por ejemplo, el RGPD o la LFPDPPP en México). En cambio, la anonimización es **irreversible**: no existe un medio razonable para volver a identificar a la persona, por lo que los datos dejan de considerarse personales.

**4. ¿Qué información permite volver a relacionar el token con una persona?**

La tabla de correspondencia **`pii.mapa_cliente`**, que vincula cada token o identificador seudónimo con el identificador real del cliente. Además, los datos originales de **`public.clientes`** también permiten la reidentificación, ya que contienen la información identificable completa.

## Actividad 6 — Análisis del riesgo de reidentificación

**1. ¿Qué identificadores directos fueron eliminados?**

La consulta final solo devuelve `rango_edad`, `region` y `total`, por lo que ya no aparecen los identificadores directos: nombre, correo electrónico, teléfono, identificador de cliente (`id`), dirección completa y cualquier otro dato que apunte a una persona concreta. Además, la salida es agregada (`COUNT(*)`), así que ya no hay registros individuales.

**2. ¿Qué cuasi-identificadores permanecen?**

- **`rango_edad`** (edad generalizada en rangos).
- **`region`** (los dos primeros dígitos del código postal).

Por sí solos no identifican a nadie, pero combinados entre sí o con fuentes externas (redes sociales, padrones, otras bases) pueden señalar a una persona.

**3. ¿Qué combinaciones de atributos podrían reducir el anonimato?**

- `rango_edad` + `region` cuando la combinación es poco frecuente (por ejemplo, '46+' en una región con muy pocos clientes).
- Cruzar el resultado con otras tablas o fuentes públicas que contengan edad, ubicación, género, ocupación, fecha de alta, etc.
- Si se agregaran más atributos (sexo, profesión, fecha de nacimiento, código postal completo), cada nueva columna fragmenta los grupos y los hace más pequeños.
- Consultas repetidas con filtros distintos (ataques de diferenciación) que permitan deducir a un individuo por resta de resultados.

**4. ¿Qué sucede cuando un grupo contiene pocos registros?**

Los individuos se vuelven fácilmente distinguibles. Un grupo con 1 o 2 personas permite que alguien que conozca a esa persona (o tenga datos externos) la identifique y deduzca información sobre ella. Por eso se aplica el umbral de supresión (`HAVING COUNT(*) >= 5`): garantiza que cada combinación publicada describa al menos 5 personas (idea de k-anonimato).

**5. ¿Qué atributos deberían generalizarse?**

- **Edad:** rangos más amplios o ajustados según la distribución de los datos.
- **Código postal / región:** usar menos dígitos, municipio, estado o macrorregión.
- Fechas (nacimiento, alta, compra): reducirlas a año o trimestre.
- Cualquier otro cuasi-identificador que se agregue después (ocupación, ingresos, etc.), pasándolo a categorías amplias.

**6. ¿Qué información debería suprimirse?**

- Los grupos con menos de `k` registros (en este ejercicio, menos de 5).
- Los identificadores directos (nombre, correo, teléfono, ID, dirección).
- Atributos muy específicos o únicos que no sean necesarios para el análisis estadístico.
- Valores atípicos (por ejemplo, edades extremas) que hagan único a un registro.

**7. ¿Es correcto afirmar que el conjunto de datos es "100 % anónimo"? ¿Por qué?**

**No.** Cumplir `k = 5` no demuestra por sí solo que los datos sean anónimos, porque:

- El k-anonimato solo protege contra la reidentificación por los cuasi-identificadores considerados; no cubre otros atributos ni fuentes externas.
- Puede haber **ataques de homogeneidad** (todos los miembros del grupo comparten el mismo valor sensible) o de **conocimiento previo**.
- Los resultados agregados pueden combinarse con otras publicaciones o consultas.
- El riesgo se reduce, pero nunca es cero; la evaluación debe considerar el contexto, los datos disponibles para un posible atacante y los medios razonables de reidentificación.

Lo correcto es decir que el conjunto tiene un **riesgo de reidentificación reducido**, no que es "100 % anónimo".

### Reto

**Consulta modificada:**

```sql
SELECT
  CASE
    WHEN edad BETWEEN 18 AND 35 THEN '18-35'
    WHEN edad BETWEEN 36 AND 55 THEN '36-55'
    ELSE '56+'
  END AS rango_edad,
  LEFT(codigo_postal, 1) AS region,
  COUNT(*) AS total
FROM clientes
GROUP BY 1, 2
HAVING COUNT(*) >= 10;
```

| Elemento | Documentación |
|---|---|
| **Cambio realizado** | Se ampliaron los rangos de edad (18-35, 36-55, 56+), se redujo la región de 2 a 1 dígito del código postal y se subió el umbral de supresión de 5 a 10 registros. |
| **Motivo** | Rangos y regiones más amplios hacen que cada grupo sea más grande y menos específico; un umbral mayor elimina los grupos pequeños que serían más fáciles de identificar. |
| **Resultado obtenido** | Menos filas en el resultado, con grupos más grandes (mínimo 10 personas cada uno). Se pierde algo de detalle estadístico, pero aumenta la protección. *(Los conteos exactos dependen de los datos de la tabla `clientes`.)* |
| **Riesgo que se pretende reducir** | Reidentificación por singularización y por vinculación con fuentes externas (combinación de edad + ubicación), así como el riesgo de inferencia en grupos pequeños. |