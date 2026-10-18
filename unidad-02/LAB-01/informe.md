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