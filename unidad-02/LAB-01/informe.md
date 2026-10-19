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

## Actividad 7 — Retención de datos: Documentación

### 1. ¿Qué registros serían afectados?

Todos los registros de `clientes` cuya `fecha_alta` sea anterior a la fecha actual menos cinco años. Con la fecha de hoy (18 de octubre de 2026), serían los clientes dados de alta **antes del 18 de octubre de 2021**.

Antes de cualquier eliminación conviene verificar:

- Cuántos registros son (`SELECT COUNT(*)` con el mismo filtro).
- Si alguno tiene una **relación vigente** (contrato activo, adeudo, litigio, reclamación o requerimiento de una autoridad), porque no debería eliminarse aunque supere el plazo.
- Si hay **datos relacionados** en otras tablas (`analitica.clientes`, `pii.mapa_cliente`, bitácoras, respaldos) que también deban tratarse.

### 2. ¿Cuál sería la justificación del periodo?

El plazo de cinco años es **hipotético**, para fines del ejercicio. En un caso real se justificaría con:

- **Principio de limitación del plazo de conservación:** los datos personales solo se conservan mientras sean necesarios para la finalidad para la que se recabaron.
- **Obligaciones legales aplicables** (fiscales, contables, mercantiles, sectoriales), que pueden exigir conservar ciertos datos por un mínimo de años.
- **Finalidad del negocio:** la relación comercial, la atención de garantías y la prevención de fraudes.
- **Política de retención documentada** de la organización, aprobada y revisada periódicamente.

### 3. ¿Qué aprobación debería existir antes de eliminar información?

- Autorización formal del **responsable del tratamiento / dueño de los datos** (área de negocio).
- Visto bueno del **área jurídica o de cumplimiento** y del **oficial de protección de datos (DPO) o responsable de privacidad**.
- Validación del **área de TI o administración de bases de datos** sobre el alcance técnico.
- Registro de la solicitud de cambio (ticket o control de cambios) con fecha, alcance, responsable y criterio aplicado.
- Confirmación de que no existe **retención legal** (*legal hold*) sobre esos registros.

### 4. ¿Qué respaldo debería existir?

- Un **respaldo completo y verificado** de la base de datos (o al menos de los registros afectados) **inmediatamente antes** de la eliminación.
- Copia de los registros a eliminar en un **almacenamiento restringido y cifrado**, con acceso limitado y periodo de resguardo definido.
- **Prueba de restauración** del respaldo para comprobar que es utilizable.
- Respaldos que respeten también la política de retención (no conservar indefinidamente lo que se eliminó).

### 5. ¿Qué evidencia debería conservarse?

- Consulta ejecutada y **número de registros** identificados y eliminados.
- Fecha, hora y **usuario** que ejecutó el procedimiento.
- **Aprobaciones** firmadas o registradas (negocio, jurídico, privacidad, TI).
- Política de retención y criterio aplicado.
- Resultado de la verificación posterior (conteos antes y después).
- Bitácoras de auditoría de la base de datos.
- Evidencia del respaldo previo y de su prueba de restauración.

La evidencia **no debe contener los datos personales eliminados**; basta con identificadores técnicos, conteos y fechas.

### 6. ¿Qué procedimiento permitiría recuperar información eliminada accidentalmente?

1. **Detener** cualquier proceso adicional de eliminación y notificar al responsable.
2. **Identificar** el alcance del error (qué registros, qué tablas, cuándo).
3. **Localizar** el respaldo previo a la eliminación (o usar recuperación a un punto en el tiempo, *point-in-time recovery*, si está disponible).
4. **Restaurar en un entorno separado** y validar la integridad de los datos recuperados.
5. **Reincorporar** únicamente los registros afectados a la tabla principal (por ejemplo, mediante `INSERT ... SELECT`), cuidando relaciones y llaves.
6. **Verificar** conteos y consistencia, y documentar el incidente con una corrección y lecciones aprendidas.
7. Una vez resuelto, **repetir el proceso de eliminación** solo con la aprobación y el alcance correctos.

## 19.1 Clasificación

Todos los campos de la tabla `clientes` necesitan protección, aunque algunos más que otros según el daño que causaría su filtración.

**Los que más protección necesitan: `nombre`, `correo`, `telefono` y `rfc`.**
Estos identifican directamente a una persona. Con ellos alguien podría contactarla, suplantarla o cometer fraude. El `rfc` es el más delicado, porque es un identificador fiscal único que además incluye la fecha de nacimiento, lo que facilita el robo de identidad.

**Los que necesitan protección moderada: `edad`, `ciudad`, `codigo_postal` y `fecha_alta`.**
Por separado no dicen quién es la persona, pero juntos sí pueden hacerlo. Por ejemplo, saber el código postal, la edad y la fecha en que se registró alguien puede bastar para reducir las opciones a una sola persona, aunque se hayan borrado el nombre y el correo. A esto se le llama reidentificación.

**El `id` también se protege.**
Aunque solo es un número interno, sirve para unir información de distintas tablas. Si se filtra junto con otras bases de datos, permite reconstruir el historial completo del cliente.

**Aspecto jurídico.**
Según la LFPDPPP, todos estos campos son datos personales porque identifican o hacen identificable a alguien. Ninguno es dato personal *sensible* (como salud, origen étnico o creencias), pero eso no significa que no deban protegerse: el nivel de protección depende del riesgo que genera su exposición, no solo de su categoría legal.

## 19.2 Enmascaramiento

**Qué se ocultó.**
Se ocultaron parcialmente tres campos de la tabla `clientes`:
- `correo`: solo se muestran las dos primeras letras y el dominio (por ejemplo, `ju*****@gmail.com`).
- `telefono`: solo se muestran los últimos cuatro dígitos (por ejemplo, `******1234`).
- `rfc`: solo se muestran los últimos cuatro caracteres (por ejemplo, `*********AB12`).

Los campos `id` y `nombre` se siguen mostrando completos, porque soporte los necesita para identificar y atender al cliente.

**Para quién.**
Para el rol `soporte`, es decir, el personal del área de soporte que consulta información de los clientes pero no necesita ver los valores completos de sus datos de contacto ni fiscales.

**Por qué.**
Porque el personal de soporte solo requiere lo suficiente para reconocer al cliente y dar seguimiento a sus casos, no para contactarlo por su cuenta ni conocer su identificador fiscal. Ocultar estos datos aplica el principio de **mínimo privilegio** y reduce el riesgo de filtración, mal uso o fraude (suplantación, phishing, robo de identidad), sobre todo con el `rfc`, que es el dato más sensible de la tabla. Aun así, los últimos dígitos visibles permiten confirmar con el cliente que se trata del registro correcto.

**Qué mecanismo se utilizó.**
Se combinaron tres mecanismos:
1. **Rol (`soporte`)**: se creó con `CREATE ROLE soporte NOLOGIN` para agrupar los permisos del área.
2. **Vista de acceso restringido (`v_clientes_soporte`)**: aplica el enmascaramiento con funciones de texto (`CONCAT`, `LEFT`, `RIGHT`, `SUBSTRING` y `POSITION`), de modo que los datos reales nunca salen de la base de datos sin ocultar.
3. **Control de permisos (`GRANT` y `REVOKE`)**: se le concedió al rol `SELECT` solo sobre la vista (más `USAGE` sobre el esquema `public`) y se le retiró todo acceso directo a la tabla `clientes`.

Con esto, al ejecutar `SELECT * FROM v_clientes_soporte` el usuario ve los datos enmascarados, y al ejecutar `SELECT * FROM clientes` el sistema le niega el acceso con un error de permisos.

## 19.3 Seudonimización

**Cómo se generaron los tokens.**
Se habilitó la extensión `pgcrypto` y se usó la función `gen_random_uuid()` para generar un UUID aleatorio por cada cliente de la tabla `clientes`. Como los tokens son aleatorios, no se derivan de ningún dato del cliente (nombre, correo, RFC, etc.), por lo que no se pueden deducir ni revertir a partir de ellos. Cada token quedó asociado a un `cliente_id` único en la tabla de correspondencia.

**Dónde se encuentra el mapa de correspondencia.**
En la tabla `pii.mapa_cliente`, dentro del esquema `pii`, que está separado del esquema `analitica`. Esta tabla es la única que relaciona cada `token` con el `id` real del cliente en `public.clientes`. El conjunto de datos de analítica (`analitica.clientes`) solo contiene el `cliente_token`, `edad`, `ciudad`, `codigo_postal` y `fecha_alta`, sin `nombre`, `correo`, `telefono` ni `rfc`.

**Quién debería poder acceder a él.**
Únicamente personal autorizado y con una necesidad justificada de reidentificar, como el administrador de la base de datos o el responsable de protección de datos. El área de analítica no debería tener acceso al esquema `pii` ni a la tabla `mapa_cliente`; solo al esquema `analitica`.

**Por qué se separaron los permisos.**
Porque la seudonimización solo funciona si quien analiza los datos no puede volver a la identidad real. Si analítica pudiera leer el mapa, bastaría un `JOIN` para reidentificar a cualquier cliente y el token perdería su utilidad. Al separar los esquemas y los permisos:
- Analítica puede estudiar tendencias (edad, ciudad, antigüedad) sin conocer quién es cada persona.
- Si el esquema de analítica se filtra, el atacante no obtiene identidades directas.
- Se aplica el principio de **mínimo privilegio** y se reduce el riesgo de uso indebido.

Cabe aclarar que los datos siguen siendo **seudonimizados, no anónimos**: como existe el mapa, la reidentificación es posible para quien lo controla. Además, la combinación de `edad`, `ciudad`, `codigo_postal` y `fecha_alta` todavía podría ayudar a reidentificar, por lo que el mapa debe protegerse con especial cuidado.

## 19.4 Anonimización

**Qué identificadores fueron eliminados.**
Las consultas para el área de dirección no incluyen `id`, `nombre`, `correo`, `telefono` ni `rfc`. Tampoco se muestra ningún registro individual: solo se devuelven conteos (`COUNT(*)`) por grupo, así que la dirección no puede ver a un cliente en particular.

**Qué atributos fueron generalizados.**
- `edad`: en lugar de la edad exacta se usan rangos (`18-30`, `31-45` y `46+`).
- `codigo_postal`: solo se conservan los dos primeros dígitos (`LEFT(codigo_postal, 2)`), lo que convierte una zona pequeña en una región más amplia.

Además, se eliminaron por completo `ciudad` y `fecha_alta`, que no aparecen en ninguna de las consultas.

**Qué grupos fueron suprimidos.**
En la consulta 12.4 se usa `HAVING COUNT(*) >= 5`, por lo que se suprimen todos los grupos (combinación de `rango_edad` y `region`) con menos de cinco clientes. Esto evita que alguien quede en un grupo muy pequeño, o incluso solo, y sea fácil de señalar. Por ejemplo, un grupo de 1 o 2 personas de 46+ años en una región concreta no aparecería en el resultado.

**Qué riesgo de reidentificación permanece.**
Aunque el riesgo baja mucho, no desaparece:
- Cumplir con `k = 5` es solo un ejercicio didáctico y **no demuestra que los datos sean completamente anónimos**. Solo garantiza que cada combinación publicada tiene al menos cinco personas, pero únicamente respecto a los atributos usados (`rango_edad` y `region`).
- Si se agregan más atributos o se cruzan los resultados con otras fuentes (redes sociales, directorios, otras bases), los grupos pueden volverse a hacer pequeños y facilitar la reidentificación.
- Si las consultas 12.1, 12.2, 12.3 y 12.4 se publican juntas, se pueden comparar los resultados (por ejemplo, restar totales) para inferir información de los grupos suprimidos.
- Si todas las personas de un grupo comparten una característica, se puede deducir ese dato de cualquiera de ellas aunque el grupo tenga cinco o más integrantes.
- Una región con pocos clientes en total puede seguir siendo identificable por el contexto.

Por eso, la evaluación real debe considerar otros atributos y posibles combinaciones, y revisarse cada vez que cambien los datos o las consultas que se entregan.

## 19.5 Retención

**Qué criterio se utilizó.**
Se usó la `fecha_alta` como criterio y un periodo de conservación hipotético de cinco años. La consulta identifica los clientes cuya fecha de alta es anterior a `CURRENT_DATE - INTERVAL '5 years'`, es decir, los registros que superan ese plazo. No se ejecutó ningún `DELETE`: el ejercicio solo busca identificar los registros afectados y diseñar el procedimiento.

**Qué información debería conservarse.**
- Los datos que la organización necesita para operar o cumplir obligaciones legales, fiscales o contractuales (por ejemplo, información de facturación o fiscal que la ley exija guardar por un plazo determinado).
- Los registros de clientes que siguen activos o con una relación vigente, aunque su fecha de alta sea antigua.
- Información agregada o anonimizada, que ya no permite identificar a nadie y puede conservarse para fines estadísticos.
- Las evidencias de la depuración (bitácoras y actas) y los respaldos mientras estén dentro de su propio periodo de resguardo.

**Qué información podría eliminarse.**
Los registros de clientes que superaron los cinco años, ya no tienen relación activa con la organización, no están sujetos a una obligación legal de conservación ni a una investigación o litigio en curso. En estos casos, mantener los datos personales ya no tiene una finalidad que lo justifique, y conservarlos solo aumenta el riesgo en caso de filtración.

**Qué controles deberían existir antes de eliminarla.**
- **Justificación del periodo:** documentar por qué se eligieron cinco años (política interna, requisitos legales o fiscales, finalidad del tratamiento), en línea con el principio de temporalidad de la LFPDPPP.
- **Revisión de los registros afectados:** validar que la lista obtenida con la consulta sea correcta y que no incluya clientes activos o con obligaciones pendientes.
- **Aprobación formal:** autorización por escrito del responsable de datos, el área jurídica o de cumplimiento y el dueño del proceso, antes de cualquier eliminación.
- **Respaldo previo:** una copia verificada de los registros a eliminar (y de la base completa), almacenada de forma segura y con acceso restringido, que se pruebe que puede restaurarse.
- **Evidencia a conservar:** la consulta ejecutada, el número y la lista de registros afectados (de preferencia seudonimizada), la fecha, quién ejecutó y quién aprobó, y el resultado de la eliminación.
- **Procedimiento de recuperación:** en caso de eliminación accidental, restaurar los registros desde el respaldo previo (o con recuperación a un punto en el tiempo) en un entorno controlado, validar la información y reinsertarla en la tabla principal, documentando el incidente. Esto se trabajará en las prácticas de respaldo y recuperación.
- **Eliminación controlada:** ejecutar primero en un entorno de pruebas, usar transacciones y limitar el `DELETE` a los registros aprobados.

## 19.6 Conclusiones

**¿Qué técnica utilizarías para un área de soporte?**
Enmascaramiento (masking). Soporte necesita reconocer al cliente y atender sus casos, pero no requiere ver completos el correo, el teléfono ni el RFC. Con una vista que muestra solo una parte de esos datos (por ejemplo, los últimos cuatro dígitos) puede trabajar sin exponer la información completa.

**¿Qué técnica utilizarías para un área de analítica?**
Seudonimización. Analítica necesita estudiar el comportamiento de los clientes (edad, ciudad, antigüedad) sin saber quiénes son. Reemplazar la identidad por un token permite analizar y relacionar registros, mientras que el mapa de correspondencia se guarda aparte, con acceso restringido.

**¿Qué técnica utilizarías para publicar estadísticas?**
Anonimización. Para publicar o entregar estadísticas a la dirección no hace falta ningún registro individual. Se generalizan los atributos (rangos de edad, regiones), se agregan los resultados y se suprimen los grupos pequeños para reducir el riesgo de reidentificación.

**¿Por qué ninguna de estas técnicas sustituye al control de acceso?**
Porque estas técnicas reducen qué tan expuesto queda el dato, pero no deciden quién puede llegar a él. Por ejemplo:
- Una vista con datos enmascarados solo protege si el rol de soporte no puede consultar directamente la tabla `clientes`. Sin `REVOKE`, el enmascaramiento se puede saltar.
- Los datos seudonimizados siguen siendo reidentificables para quien tenga el mapa `pii.mapa_cliente`. Si analítica lo pudiera leer, el token no serviría de nada.
- Los datos anonimizados todavía pueden conservar un riesgo residual de reidentificación, sobre todo si se cruzan con otras fuentes, y cumplir con `k = 5` no prueba que sean completamente anónimos.

Por eso estas técnicas funcionan como capas complementarias dentro de una estrategia de **defensa en profundidad**: el control de acceso (roles, permisos, separación de esquemas y mínimo privilegio) define quién puede ver qué, y el enmascaramiento, la seudonimización y la anonimización limitan el daño si ese control falla o si alguien accede a los datos con permisos legítimos pero más amplios de lo necesario.

## 20. Preguntas de reflexión

**1. ¿Cuál es la diferencia entre enmascaramiento y seudonimización?**
El enmascaramiento oculta parte de un dato al mostrarlo (por ejemplo, `ju*****@gmail.com`), y el usuario sigue viendo el mismo registro con valores parcialmente tapados. La seudonimización reemplaza los identificadores por un token (un UUID) y guarda la correspondencia en otro lugar, de modo que quien analiza los datos no sabe de quién son. El primero busca que se vea menos del dato; la segunda, que el dato no esté ligado directamente a una identidad.

**2. ¿Por qué la seudonimización no significa anonimización?**
Porque existe un mapa (`pii.mapa_cliente`) que permite volver del token al cliente real. Mientras la reidentificación sea posible, aunque sea para quien controla el mapa, los datos siguen siendo personales. En la anonimización no debería existir una forma razonable de volver a la persona.

**3. ¿Por qué eliminar `nombre` y `RFC` no garantiza que un conjunto de datos sea anónimo?**
Porque los demás campos pueden identificar por combinación. Atributos como `edad`, `ciudad`, `codigo_postal` y `fecha_alta` reducen el grupo de candidatos y, cruzados con fuentes externas (redes sociales, directorios, otras bases), pueden señalar a una sola persona. Quitar los identificadores directos reduce el riesgo, pero no lo elimina.

**4. ¿Qué función tienen los cuasi-identificadores?**
No identifican por sí solos, pero al combinarse permiten acotar a una persona o reidentificarla. Por eso hay que detectarlos y tratarlos con generalización (rangos de edad, región en lugar de código postal completo), supresión de grupos pequeños o agregación.

**5. ¿Por qué es importante separar el mapa de seudonimización?**
Porque el mapa es lo único que permite reidentificar. Si estuviera junto a los datos de analítica, bastaría un `JOIN` para saber quién es cada cliente y el token perdería su utilidad. Al guardarlo en otro esquema (`pii`) con permisos propios, una filtración de los datos analíticos no revela identidades.

**6. ¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?**
El principio de **mínimo privilegio**: cada usuario solo debe tener los permisos necesarios para su tarea. También se aplica la **separación de funciones** (quien analiza no es quien puede reidentificar) y la **necesidad de saber**.

**7. ¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?**
Porque la vista expone solo las columnas y los valores necesarios, ya transformados (por ejemplo, enmascarados), mientras que la tabla original queda inaccesible para ese rol. Además, centraliza la regla de protección en un solo lugar, es fácil de auditar y evita que el usuario vea o consulte campos que no necesita.

**8. ¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra acceso no autorizado?**
Proteger para visualización (enmascarar, generalizar) controla *cómo se ve* el dato para quien ya tiene acceso legítimo. Proteger contra acceso no autorizado (roles, permisos, autenticación, cifrado) controla *quién puede llegar* al dato. Lo primero no sustituye a lo segundo: un dato enmascarado en una vista sigue completo en la tabla original si esta no está protegida.

**9. ¿Por qué la retención forma parte de la protección de datos?**
Porque proteger datos también implica no conservarlos más tiempo del necesario. La LFPDPPP establece el principio de temporalidad: los datos deben guardarse solo mientras sean necesarios para la finalidad que justificó su tratamiento o para cumplir obligaciones legales. Una política de retención reduce la cantidad de información expuesta y demuestra un tratamiento responsable.

**10. ¿Qué riesgo existe si una organización conserva información indefinidamente?**
Aumenta la superficie de ataque: ante una filtración o brecha se expone más información, incluida la de clientes que ya no tienen relación con la organización. También se incumplen principios legales (temporalidad, proporcionalidad), crece el costo de almacenamiento y gestión, aumentan las posibles sanciones y se corre el riesgo de usar datos desactualizados o con una finalidad distinta a la original.