# Actividad 1

## 1. Matriz de identificación y protección de datos

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

## 2. Preguntas

### 1. ¿Qué campos identifican directamente a una persona?

Los campos que pueden identificar directamente a una persona son `nombre`, `correo`, `telefono` y `rfc`. El campo `id` también puede hacerlo cuando está asociado con una persona específica dentro de una base de datos.

### 2. ¿Qué campos no identifican por sí solos pero podrían contribuir a hacerlo?

Los campos `edad`, `ciudad`, `codigo_postal` y `fecha_alta` generalmente no identifican por sí solos a una persona, pero pueden facilitar su identificación cuando se combinan con otros datos.

### 3. ¿Qué combinación de campos podría incrementar el riesgo de reidentificación?

Una combinación como `edad`, `ciudad`, `codigo_postal` y `fecha_alta` puede incrementar el riesgo de reidentificación, ya que permite reducir el número de personas que coinciden con esas características. Si además se agrega el nombre, el correo o el RFC, la identificación puede resultar mucho más sencilla.

### 4. ¿Todos los datos que deben protegerse son necesariamente datos personales sensibles desde el punto de vista jurídico?

No. No todos los datos que requieren protección son considerados datos personales sensibles desde el punto de vista jurídico. Los datos personales son aquellos que permiten identificar o hacer identificable a una persona, mientras que los datos personales sensibles son una categoría específica que incluye información relacionada con la salud, el origen racial o étnico, las creencias religiosas y otros aspectos íntimos cuya utilización indebida puede generar discriminación o un riesgo grave para la persona.

Por lo tanto, datos como el nombre, el correo electrónico, el teléfono y el RFC deben protegerse, aunque no necesariamente se clasifiquen como datos personales sensibles.
