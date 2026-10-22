# Informe final

## 1. Introducción

Una empresa mantiene una base de datos con información de **50,000 clientes** (nombre, correo, teléfono, RFC, edad, ciudad y código postal). El análisis de la tabla `clientes` y su entorno reveló problemas de privacidad que no son fallas de seguridad "clásicas", sino de **uso y gestión de los datos**:

- El área de analítica consulta directamente la tabla completa, aunque solo genera estadísticas mensuales.
- Los datos se conservan desde hace 12 años, sin política documentada de retención.
- Los desarrolladores reciben copias completas con información real.
- Marketing utiliza los correos para campañas promocionales sin evidencia clara de finalidad ni consentimiento.
- No existe documentación de la finalidad de cada dato.

El problema central es que la organización **tiene los datos, pero no ha definido con claridad para qué, quién, por cuánto tiempo ni bajo qué condiciones puede tratarlos**. Este informe analiza el caso desde la perspectiva del DBA, aplicando los principios de finalidad, consentimiento, minimización, mínimo privilegio, retención, trazabilidad y los derechos ARCO (LFPDPPP).

## 2. Inventario de datos

| Dato | Tipo | Clasificación | Sensibilidad | Observaciones |
|---|---|---|---|---|
| `id` | Identificador interno | Interna | Baja | Permite vincular registros sin exponer identidad; base para seudonimización. |
| `nombre` | Identificación | Confidencial | Media | Identifica directamente a la persona. |
| `correo` | Contacto | Confidencial | Media-alta | Identificador directo; se usa para marketing (finalidad secundaria). |
| `telefono` | Contacto | Confidencial | Media | Depende del canal de comunicación. |
| `rfc` | Fiscal | Confidencial / restringido | Alta | Dato fiscal; riesgo de fraude y suplantación. |
| `edad` | Demográfico | Interna | Baja-media | Puede generalizarse en rangos. |
| `ciudad` | Ubicación general | Interna | Baja | Útil para segmentación; riesgo bajo por sí sola. |
| `codigo_postal` | Ubicación | Confidencial | Media | Combinado con edad y ciudad permite reidentificar. |
| Comportamiento de compra | Derivado | Confidencial | Media | Genera perfiles; debe agregarse o resumirse. |
| Consentimientos | Gestión | Confidencial | Media | Evidencia de finalidades aceptadas o rechazadas. |
| Bitácoras de auditoría | Gestión | Restringida | Media | Contienen datos personales (valores anteriores y nuevos). |

Los datos también existen fuera de la tabla principal: **respaldos, réplicas, copias de desarrollo, vistas de analítica, exportaciones y sistemas externos**, lo que debe incluirse en el mapa de datos.

## 3. Finalidades

| Finalidad | Tipo | Datos que se utilizan |
|---|---|---|
| Atención al cliente y entrega de productos o servicios | Primaria | `id`, nombre, correo, teléfono, ciudad |
| Facturación y cumplimiento fiscal | Primaria | nombre, RFC, código postal |
| Estadísticas mensuales | Secundaria (analítica) | seudónimo, rango de edad, ciudad, comportamiento resumido |
| Promociones y campañas | Secundaria (marketing) | correo (o canal), ciudad, rango de edad, segmento de compra; solo con consentimiento u oportunidad de oposición |

Reglas aplicadas:

- Tener los datos **no autoriza a usarlos para cualquier propósito**.
- Las finalidades secundarias deben estar en el aviso de privacidad y permitir que el titular se niegue.
- Cada dato debe asociarse a una finalidad concreta; si no la tiene, no debería almacenarse.

## 4. Minimización

| Dato | Decisión | Por qué |
|---|---|---|
| `nombre`, `correo`, `telefono` | **Limitar** | Solo para atención y contacto; no deben llegar a analítica. |
| `rfc` | **Limitar / separar** | Solo para facturación; en tabla restringida, cifrado, fuera de analítica y marketing. |
| `codigo_postal` | **Eliminar de analítica y marketing** | Con la ciudad es suficiente; combinado con otros datos facilita la reidentificación. |
| `edad` | **Generalizar** | Un rango de edad basta para estadísticas y segmentación. |
| `ciudad` | **Conservar** | Segmentación geográfica de bajo riesgo. |
| Comportamiento de compra | **Resumir** | Categorías o frecuencia, no historial detallado. |
| Campos "por si acaso" (salario, estado civil, ocupación, fecha de nacimiento) | **No recolectar / eliminar** | Sin finalidad definida y de alto riesgo. |
| Datos con 12 años de antigüedad sin finalidad vigente | **Depurar** | Se eliminan, bloquean o anonimizan, salvo obligación legal. |

## 5. Control de acceso

El acceso se relacionó con la **necesidad funcional** de cada rol (mínimo privilegio):

| Dato | Atención al cliente | Facturación | Analítica | Marketing | DBA | Dirección |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| `nombre` | Sí | Sí | No | No | Mantenimiento / ARCO | No |
| `correo` | Sí | Limitado | No | Solo con consentimiento | Mantenimiento / ARCO | No |
| `telefono` | Sí | No | No | Solo si hay canal | Mantenimiento / ARCO | No |
| `rfc` | No | Sí | No | No | Mantenimiento / ARCO | Solo agregado |
| `edad` | No | No | Rango | Rango | Mantenimiento | Solo agregado |
| `ciudad` | Sí | No | Sí | Sí | Mantenimiento | Solo agregado |
| `codigo_postal` | No | Sí | No | No | Mantenimiento / ARCO | No |

## 6. Derechos ARCO

| Derecho | Implicaciones técnicas |
|---|---|
| **Acceso** | Verificar identidad antes de consultar; localizar al titular en tablas relacionadas, respaldos, logs, exportaciones y sistemas externos; el correo puede no ser único (trabajar con `id`); entrega segura y legible; rol ARCO limitado; auditoría. |
| **Rectificación** | Solicitud documentada con folio; validar la titularidad del nuevo dato; ejecución con rol autorizado; tabla de auditoría con trigger (quién, cuándo, valor anterior, valor nuevo, folio); propagación a copias y sistemas externos. |
| **Cancelación** | No ejecutar solo un `DELETE`: analizar tablas relacionadas, respaldos, réplicas, analítica, exportaciones y sistemas externos; distinguir eliminar, **bloquear** (obligación legal) y anonimizar; documentar la expiración de respaldos; notificar a terceros. |
| **Oposición** | No implica borrar todo, sino dejar de usar los datos para una finalidad; consentimientos por finalidad, vistas filtradas, lista de exclusión y propagación a CRM y plataformas de correo. |

## 7. Retención

El periodo de conservación **no debe fijarse por conveniencia ("por si acaso")**, sino determinarse a partir de:

1. **Finalidad:** hasta cuándo se necesita el dato para cumplirla.
2. **Obligaciones legales:** plazos fiscales, contables, mercantiles u otros.
3. **Obligaciones contractuales y plazos de prescripción:** garantías y posibles reclamaciones.
4. **Categoría y sensibilidad del dato:** periodos distintos por tipo de dato.
5. **Evento que inicia el conteo:** última compra, cierre de cuenta o fin del contrato.
6. **Riesgo:** impacto de una filtración.
7. **Ubicaciones:** tablas, respaldos, réplicas, analítica, exportaciones y terceros.
8. **Acción al vencer:** eliminar, bloquear o anonimizar.
9. **Excepciones:** litigios o requerimientos de autoridad.

Debe documentarse: categoría, finalidad, fundamento, periodo, justificación, acción al vencimiento, responsables y evidencia de ejecución. Técnicamente se implementa con `fecha_retencion`, tareas programadas de depuración y bitácoras.

## 8. Gobierno de datos

### Matriz de responsabilidades

| Actor | Responsabilidad principal |
|---|---|
| **Dirección** | Aprueba políticas, asigna recursos y responsables. |
| **Responsable de privacidad** | Aviso de privacidad, consentimientos, validación de identidad y gestión de solicitudes ARCO. |
| **Área jurídica** | Licitud de finalidades, plazos legales, excepciones y transferencias a terceros. |
| **Propietario del dato (negocio)** | Justifica la necesidad funcional y define el uso del dato. |
| **Seguridad de la información** | Define y verifica los controles de protección. |
| **DBA** | Implementa roles, vistas, cifrado, auditoría y retención; ejecuta ARCO validadas. |
| **Desarrollo** | Trabaja con datos sintéticos o enmascarados. |

## 9. Evaluación integral

| # | Problema | Principio afectado | Riesgo | Control propuesto |
|---|---|---|---|---|
| 1 | Analítica accede directamente a `clientes` | Mínimo privilegio | Acceso indebido a datos innecesarios | Rol de analítica solo sobre `v_analitica_clientes` |
| 2 | Analítica ve datos identificables para estadísticas | Minimización | Exposición innecesaria | Vista con seudónimo, rango de edad y ciudad |
| 3 | Conservación de 12 años | Limitación de la conservación | Tratamiento sin finalidad vigente | Depuración: eliminar, bloquear o anonimizar |
| 4 | Sin política de retención | Responsabilidad | Conservación indefinida de hecho | Política por categoría y tareas de depuración |
| 5 | Copias completas para desarrolladores | Minimización / seguridad | Difusión de datos fuera de control | Prohibir copias completas; datos sintéticos o enmascarados |
| 6 | Datos reales en desarrollo | Seguridad / finalidad | Filtración en entornos débiles | Enmascaramiento irreversible |
| 7 | Marketing usa correos sin evidencia de consentimiento | Finalidad / consentimiento | Tratamiento secundario no informado; sanciones | Consentimientos por finalidad, vista filtrada, lista de exclusión |
| 8 | Finalidades no documentadas | Responsabilidad / transparencia | No se puede justificar cada uso | Matriz de gobierno de datos |
| 9 | RFC, teléfono y código postal sin justificación para todos los usos | Proporcionalidad | Datos fiscales y de contacto expuestos | Tabla separada, cifrado y acceso restringido |
| 10 | Sin trazabilidad visible | Responsabilidad / seguridad | No se detectan abusos ni se reconstruyen incidentes | Auditoría y revisión de bitácoras |
| 11 | Sin procedimiento ARCO ni mapa de datos | Derechos ARCO | No se atienden solicitudes en plazo | Procedimiento ARCO e inventario de datos |
| 12 | Datos combinables que reidentifican | Minimización | Reidentificación en estadísticas | Generalizar y usar cohortes mínimas |
| 13 | Sin clasificación ni responsables | Responsabilidad | Protección uniforme para datos distintos | Clasificar y asignar dueños |
| 14 | Sin control de exportaciones | Confidencialidad | Copias locales sin control | Límites de exportación y registro |

## 10. Conclusiones

El análisis muestra que **seguridad, privacidad y administración de bases de datos están estrechamente relacionadas, pero no son lo mismo**. La seguridad protege los datos contra accesos indebidos, pérdida o alteración. La privacidad regula si la organización puede tratar esos datos, para qué, con qué límites y por cuánto tiempo. La administración de bases de datos es el punto donde ambos conceptos se vuelven decisiones concretas: roles, vistas, cifrado, auditoría, retención, respaldos y entornos de prueba.

Aprendí que:

- Una base de datos bien protegida puede violar la privacidad si se usa para finalidades no informadas o si conserva datos sin límite.
- Los principios de minimización y mínimo privilegio se traducen en vistas, roles, generalización y seudonimización.
- Los derechos ARCO obligan a conocer dónde está cada dato, incluyendo respaldos, réplicas, analítica y sistemas externos.
- La retención forma parte del ciclo de vida del dato y debe documentarse y ejecutarse técnicamente.
- El DBA es **custodio técnico**, no dueño de los datos: implementa lo que privacidad, legal y negocio deciden, y deja evidencia.
- La privacidad debe aplicarse **desde el diseño y por defecto**, porque corregirla después es más costoso y menos efectivo.

## Preguntas de reflexión

### 1. ¿Una base de datos técnicamente segura necesariamente cumple con todos los requisitos de privacidad?

**No.** La seguridad garantiza confidencialidad, integridad y disponibilidad, pero no define si el tratamiento es legítimo. Una base cifrada y con acceso controlado puede incumplir la privacidad si usa los datos para finalidades no informadas, recolecta más de lo necesario, conserva datos indefinidamente o no permite ejercer los derechos ARCO. La seguridad es necesaria, pero no suficiente.

### 2. ¿Por qué el principio de mínimo privilegio también contribuye a la privacidad?

Porque limita quién puede ver o usar cada dato según su función. Si cada rol accede solo a lo necesario, se reduce el uso indebido, la exposición interna y el impacto de una filtración, y se evita que los datos se usen para finalidades distintas a las autorizadas. Por ejemplo, analítica no necesita RFC ni nombre, y al no tenerlos se respeta la minimización y la finalidad.

### 3. ¿Por qué el DBA no debería decidir por sí solo la finalidad del tratamiento de los datos?

Porque la finalidad es una decisión legal y de negocio, no técnica. Debe estar respaldada por el aviso de privacidad, el consentimiento y la normativa, lo cual corresponde a privacidad, legal y los propietarios del dato. Además, concentrar decisión y ejecución en una persona elimina el control cruzado y aumenta el riesgo de error o abuso. El DBA tiene el acceso técnico, pero no la competencia ni la autoridad para decidir qué usos son legítimos.

### 4. ¿Por qué los desarrolladores no deberían recibir automáticamente copias completas de bases de datos productivas?

Porque la mayoría no necesita datos reales para desarrollar o probar, y entregarlos viola la minimización y el mínimo privilegio. Las copias completas amplían el número de personas y lugares con acceso a información personal, con controles más débiles que producción, y complican los derechos ARCO. Deben recibir datos sintéticos, enmascarados o un subconjunto mínimo anonimizado.

### 5. ¿Por qué una copia utilizada para desarrollo también puede representar un riesgo de privacidad?

Porque contiene los mismos datos personales reales, pero suele estar en entornos con menor seguridad: laptops, servidores de prueba, repositorios o nubes con permisos amplios. Puede filtrarse, perderse o usarse para fines distintos. Además, el titular tiene derecho a cancelar sus datos de **todas** las copias, y una copia olvidada en desarrollo hace imposible cumplirlo. La privacidad aplica a los datos, sin importar en qué entorno estén.

### 6. ¿Por qué la retención debe formar parte del ciclo de vida de los datos?

Porque los datos solo deben conservarse mientras exista una finalidad vigente u obligación legal. Un ciclo de vida completo incluye captura, uso, almacenamiento, retención y eliminación. Sin retención, los datos se acumulan indefinidamente, aumentan el riesgo de seguridad y legal, se deterioran en calidad y dificultan atender solicitudes ARCO. Definir la retención desde el diseño permite automatizar la eliminación, bloqueo o anonimización y demostrar cumplimiento.

### 7. ¿Qué relación existe entre privacidad por diseño y diseño de bases de datos?

El diseño de la base de datos es donde se concreta la privacidad por diseño. Decisiones como qué columnas crear, qué tablas separar por finalidad, qué llaves y restricciones definir, qué vistas exponer, qué campos de consentimiento y retención incluir y qué datos cifrar determinan desde el inicio cuánta información se recolecta y quién puede acceder a ella. Diseñar con privacidad desde el principio es más barato y efectivo que corregir después, cuando ya existen copias, respaldos y procesos dependientes.

### 8. ¿Qué controles técnicos implementaría para reducir el riesgo de exposición de datos personales?

- **Roles y permisos mínimos**, sin acceso directo a tablas base.
- **Vistas** con datos mínimos por finalidad y **Row-Level Security**.
- **Cifrado** en reposo y en tránsito, y cifrado de columnas sensibles (RFC).
- **Seudonimización, generalización y enmascaramiento**.
- **Separación por esquemas**: operación, analítica y auditoría.
- **Auditoría** de consultas, cambios y exportaciones, con bitácoras de solo inserción.
- **Límites de exportación** y descargas controladas.
- **Datos sintéticos o enmascarados** en desarrollo y pruebas.
- **Retención automatizada** con eliminación o anonimización programada.
- **Consentimiento por finalidad** y lista de exclusión.
- **Gestión de respaldos y réplicas** con plazos definidos y cifrado.

### 9. ¿Qué información debería conocer un DBA para responder técnicamente a una solicitud ARCO?

- La **solicitud validada**: folio, tipo de derecho, fecha y confirmación de identidad por el área responsable.
- El **identificador del titular** (`id`) y los datos para localizarlo, considerando que el correo puede no ser único.
- El **mapa de datos**: tablas relacionadas, respaldos, réplicas, analítica, exportaciones, logs y sistemas externos.
- Las **finalidades y consentimientos** vigentes del titular.
- La **política de retención** y las obligaciones legales que obligan a conservar ciertos datos.
- Las **dependencias técnicas**: llaves foráneas, `ON DELETE CASCADE`, procesos de ETL y sincronizaciones.
- El **rol ARCO** autorizado y el procedimiento para registrar la acción en auditoría.
- Los **plazos** de respuesta y el formato y canal seguro de entrega.

### 10. ¿Qué responsabilidades deberían corresponder al DBA, al responsable de privacidad, al área jurídica y al propietario de los datos?

| Actor | Responsabilidades |
|---|---|
| **DBA** | Implementar roles, vistas, cifrado, auditoría y retención; ejecutar solicitudes ARCO validadas con rol específico; gestionar respaldos, réplicas y entornos de prueba; alertar sobre riesgos técnicos y dejar evidencia. |
| **Responsable de privacidad** | Administrar el aviso de privacidad y los consentimientos; validar la identidad del solicitante; recibir, gestionar y responder las solicitudes ARCO; coordinar el cumplimiento y la capacitación. |
| **Área jurídica** | Determinar la licitud de las finalidades, los plazos legales de conservación, las excepciones a cancelación u oposición y las condiciones de transferencia a terceros; asesorar ante incidentes y autoridades. |
| **Propietario de los datos** | Justificar la necesidad funcional de cada dato, definir su uso y los usuarios autorizados, y responder por su calidad y por cumplir las finalidades aprobadas. |

La decisión sobre los datos es **compartida y documentada**: negocio propone el uso, jurídico y privacidad validan su licitud, la dirección aprueba y el DBA implementa técnicamente.