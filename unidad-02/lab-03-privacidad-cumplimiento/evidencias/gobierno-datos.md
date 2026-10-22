# Evidencia 5

## Objetivo

Construir una matriz de gobierno de datos para los principales campos de la tabla `clientes` (`nombre`, `correo`, `telefono`, `rfc`, `edad`, `ciudad`, `codigo_postal`), definiendo para cada uno su finalidad, responsable, usuarios autorizados, protección, retención y acción al finalizar. El propósito es demostrar que **el acceso a cada dato debe estar relacionado con una necesidad funcional**, y no otorgarse a todos los roles por defecto.

## Procedimiento

1. Se identificó la finalidad principal de cada campo (atención, facturación, analítica, contacto).
2. Se asignó un **responsable** (dueño del dato) a cada campo, distinto del DBA, quien actúa como custodio técnico.
3. Se determinó qué roles necesitan realmente cada dato, aplicando el principio de **mínimo privilegio**. Los roles considerados fueron: Atención al cliente, Facturación, Analítica, DBA y Dirección.
4. Se definieron controles de protección acordes a la sensibilidad de cada dato (enmascaramiento, generalización, seudonimización, cifrado, vistas, auditoría).
5. Se propuso un criterio de retención y una acción al finalizar (eliminar, bloquear o anonimizar), basados en la finalidad y en las obligaciones legales.
6. Se construyó una matriz complementaria de acceso por rol para comprobar que ningún rol tiene acceso a datos que no necesita.

# Actividad 11 — Diseñar una matriz de gobierno de datos

## Matriz de gobierno de datos

| Dato | Finalidad | Responsable | Usuarios autorizados | Protección | Retención | Acción al finalizar |
|---|---|---|---|---|---|---|
| `nombre` | Identificar al cliente en la atención y en la emisión de facturas. | Atención al cliente | Atención al cliente, Facturación. DBA solo para mantenimiento o solicitudes ARCO. | Acceso mediante vista con permisos por rol; auditoría de consultas; no se expone en analítica. | Vigencia de la relación comercial más el plazo definido por la política. | Eliminar o anonimizar; conservar bloqueado solo si está ligado a facturas con obligación fiscal. |
| `correo` | Contacto con el cliente (confirmaciones, atención, notificaciones). | Atención al cliente | Atención al cliente. Facturación solo para enviar comprobantes. DBA solo para mantenimiento o ARCO. | Enmascaramiento parcial; cifrado en reposo y en tránsito; auditoría; límite de exportación. | Vigencia de la relación comercial; el uso promocional depende del consentimiento. | Eliminar; si hubo oposición, conservar solo en lista de exclusión (id o hash). |
| `telefono` | Contacto operativo (aclaraciones, entregas) y, si aplica, SMS o WhatsApp. | Atención al cliente | Atención al cliente. DBA solo para mantenimiento o ARCO. | Enmascaramiento parcial; auditoría; acceso solo a registros de clientes atendidos. | Vigencia de la relación comercial. | Eliminar. |
| `rfc` | Emisión de facturas y cumplimiento de obligaciones fiscales. | Facturación | Facturación. DBA solo para mantenimiento o ARCO. Dirección solo en reportes fiscales agregados, sin identificar. | Cifrado de la columna; acceso restringido por rol; auditoría de consultas y exportaciones; excluido de vistas de analítica. | Plazo fiscal aplicable (en México, generalmente 5 años; confirmar con el área legal y contable). | Bloquear al terminar la relación y eliminar al vencer el plazo fiscal. |
| `edad` | Segmentación y análisis por grupo de edad. | Analítica | Analítica (como rango de edad). Dirección (indicadores agregados). DBA solo para mantenimiento. | Generalización (rangos en lugar de valor exacto); vista de analítica sin identificadores. | Mientras sea útil para el análisis, con límite definido por la política. | Anonimizar o eliminar. |
| `ciudad` | Segmentación geográfica y análisis de ventas por zona. | Analítica | Analítica. Atención al cliente. Dirección (agregado por región). DBA solo para mantenimiento. | Vista de analítica con datos agregados o seudonimizados; riesgo bajo. | Mientras sea útil para el análisis, con límite definido por la política. | Anonimizar o eliminar. |
| `codigo_postal` | Domicilio fiscal y, en su caso, entrega; no se usa para analítica. | Facturación | Facturación. DBA solo para mantenimiento o ARCO. | Acceso restringido por rol; excluido de vistas de analítica y marketing (con la ciudad es suficiente); auditoría. | Mismo plazo que los datos fiscales cuando forma parte del domicilio fiscal. | Bloquear y eliminar al vencer el plazo fiscal; en analítica, sustituir por región o ciudad. |

## Matriz de acceso por rol

| Dato | Atención al cliente | Facturación | Analítica | DBA | Dirección |
|---|:---:|:---:|:---:|:---:|:---:|
| `nombre` | Sí | Sí | No | Mantenimiento / ARCO | No |
| `correo` | Sí | Limitado (envío de comprobantes) | No | Mantenimiento / ARCO | No |
| `telefono` | Sí | No | No | Mantenimiento / ARCO | No |
| `rfc` | No | Sí | No | Mantenimiento / ARCO | Solo agregado |
| `edad` | No | No | Sí (rango) | Mantenimiento | Solo agregado |
| `ciudad` | Sí | No | Sí | Mantenimiento | Solo agregado |
| `codigo_postal` | No | Sí | No | Mantenimiento / ARCO | No |


## Análisis

- **El acceso se deriva de la función.** Atención al cliente necesita nombre, correo y teléfono para comunicarse, pero no el RFC. Facturación necesita RFC y código postal, pero no el teléfono. Analítica solo necesita datos generalizados (rango de edad, ciudad). Ningún rol recibe acceso completo a la tabla.
- **El DBA es custodio, no usuario del dato.** Tiene acceso técnico para mantener la base de datos y ejecutar solicitudes ARCO, pero no es dueño de los datos ni los utiliza para fines de negocio. Su acceso debe hacerse con un rol específico y quedar auditado.
- **Dirección trabaja con información agregada.** Para tomar decisiones no necesita identificar a ningún cliente, por lo que se le entregan indicadores y no datos individuales.
- **La sensibilidad determina la protección.** El RFC y el correo, por su capacidad de identificar a una persona o de usarse para fraude, requieren más controles (cifrado, auditoría, límites de exportación) que la ciudad, que por sí sola tiene un riesgo bajo.
- **La retención depende de la finalidad.** Los datos fiscales se conservan por obligación legal y después se eliminan; los datos de contacto, mientras dure la relación; los de analítica, mientras sigan siendo útiles y siempre que se generalicen o anonimicen.
- **La acción al finalizar evita la retención indefinida.** Definir si cada dato se elimina, bloquea o anonimiza impide conservar información "por si acaso" y facilita atender derechos de cancelación.
- **Datos de apariencia inocua pueden identificar en conjunto.** Edad, ciudad y código postal combinados pueden reidentificar a una persona, por lo que se generalizan y no se entregan juntos a analítica.

## Conclusión

La matriz de gobierno de datos demuestra que **el acceso debe estar justificado por una necesidad funcional**: cada rol ve únicamente los campos que requiere para su tarea, cada dato tiene un responsable y una finalidad definida, y todo dato tiene un ciclo de vida con una acción clara al finalizar. Este enfoque aplica los principios de finalidad, minimización, mínimo privilegio y limitación de la conservación, reduce el riesgo ante filtraciones o usos indebidos y facilita atender los derechos ARCO. Una matriz de este tipo debe ser un documento vivo, aprobado por las áreas de privacidad, legal y negocio, e implementado técnicamente mediante vistas, roles, enmascaramiento y auditoría.