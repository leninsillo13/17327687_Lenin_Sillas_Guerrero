# Evidencia 6

## Objetivo

Aplicar los principios de **privacidad por diseño y por defecto** al análisis de una tabla de clientes, y **diferenciar los controles técnicos de los administrativos** en la protección de datos personales, identificando:

- Qué problemas de privacidad presenta un diseño que recolecta datos "por si acaso".
- Qué principio se ignora, qué preguntas formular antes de aprobar el diseño y qué datos eliminar o justificar.
- Cómo aplicar la privacidad por defecto.
- Cuándo una medida de protección es técnica, administrativa o mixta.

## Procedimiento

**Actividad 12 — Privacidad por diseño**

1. Se analizó el diseño de la tabla de clientes para identificar los problemas de privacidad.
2. Se determinó el principio de privacidad que se estaba ignorando.
3. Se formularon las preguntas que deben hacerse antes de aprobar el diseño.
4. Se decidió qué datos eliminar o sustituir.
5. Se identificaron los datos que requieren una justificación adicional.
6. Se definieron las medidas para aplicar la privacidad por defecto.

**Actividad 13 — Controles técnicos y administrativos**

1. Se clasificaron ocho medidas de protección como técnicas, administrativas o mixtas.
2. Se justificó la clasificación de cada medida, distinguiendo su base de decisión y su ejecución.


# Actividad 12 — Privacidad por diseño

## Preguntas

### 1. ¿Qué problemas identifico?

| Problema | Descripción |
|---|---|
| **Recolección excesiva** | Se solicitan datos sin una finalidad definida (salario, estado civil, ocupación). |
| **Justificación especulativa** | "Por si acaso" no es una finalidad válida ni informable en el aviso de privacidad. |
| **Datos redundantes** | `edad` y `fecha_nacimiento` representan la misma información; además, la edad se desactualiza. |
| **Datos sensibles o de alto riesgo** | Salario y estado civil son datos patrimoniales y personales que aumentan el impacto de una filtración. |
| **Falta de llave primaria** | `id BIGSERIAL` no declara `PRIMARY KEY`, por lo que no garantiza unicidad. |
| **Sin restricciones de integridad** | No hay `NOT NULL`, `UNIQUE` ni validaciones (por ejemplo, para el correo o la edad). |
| **Sin control de consentimiento** | No existe campo ni tabla para registrar finalidades aceptadas o rechazadas. |
| **Sin ciclo de vida** | No hay fechas de alta, actualización ni de vencimiento para aplicar retención. |
| **Mezcla de finalidades** | Datos de contacto, fiscales y socioeconómicos están en una sola tabla y se pueden exponer juntos. |
| **Mayor superficie de riesgo** | Más datos implican más impacto ante filtraciones, más dificultad para atender derechos ARCO y mayor costo de protección. |
| **Posible reidentificación** | Combinaciones como fecha de nacimiento, código postal y ocupación permiten identificar a una persona incluso en datos "analíticos". |

### 2. ¿Qué principio de privacidad se está ignorando?

El principio de **minimización de datos**: solo deben recolectarse los datos necesarios para las finalidades informadas. El diseño además ignora:

- **Finalidad:** no hay un propósito definido para cada dato.
- **Proporcionalidad:** se recaba más de lo razonable.
- **Limitación de la conservación:** no hay plazo ni mecanismo de eliminación.
- **Privacidad por diseño y por defecto:** la protección no está incorporada desde el diseño.

### 3. ¿Qué preguntas realizaría antes de aprobar el diseño?

| Tema | Pregunta |
|---|---|
| **Finalidad** | ¿Para qué se usará cada campo? ¿Qué proceso del negocio depende de él? |
| **Necesidad** | ¿La aplicación funcionaría sin este dato? ¿Puede obtenerse después, solo cuando sea necesario? |
| **Aviso de privacidad** | ¿Todas las finalidades están incluidas en el aviso? ¿Se informa al titular? |
| **Consentimiento** | ¿Qué datos requieren consentimiento? ¿Cómo se registrará y cómo podrá revocarse? |
| **Minimización** | ¿Se puede lograr el objetivo con datos generalizados (rango de edad en lugar de fecha de nacimiento)? |
| **Sensibilidad** | ¿Algún dato es sensible o patrimonial? ¿Qué pasaría si se filtra? |
| **Acceso** | ¿Quién usará cada dato? ¿Qué roles necesitan verlo? |
| **Retención** | ¿Cuánto tiempo se conservará cada dato y qué se hará al vencer el plazo? |
| **Derechos ARCO** | ¿Cómo se atenderán acceso, rectificación, cancelación y oposición? |
| **Seguridad** | ¿Qué cifrado, auditoría y controles se aplicarán? |
| **Terceros** | ¿Se compartirán los datos con proveedores o agencias? |
| **Menores** | ¿La aplicación puede registrar menores de edad? |
| **Evaluación de riesgo** | ¿Se realizó una evaluación de impacto en privacidad? |

### 4. ¿Qué datos eliminaría?

| Dato | Decisión | Motivo |
|---|---|---|
| `salario` | **Eliminar** | Dato patrimonial sin relación con el registro de clientes; alto riesgo. |
| `estado_civil` | **Eliminar** | No es necesario para la operación; dato personal que puede ser discriminatorio. |
| `ocupacion` | **Eliminar** | Sin finalidad definida. |
| `fecha_nacimiento` | **Eliminar** (o sustituir) | Excesivo si solo se requiere saber si es mayor de edad o un rango de edad. |
| `edad` | **Eliminar** o sustituir por `rango_edad` | Se desactualiza y es redundante con la fecha de nacimiento. |
| `direccion` | **Eliminar** si no hay entregas ni domicilio fiscal | Se solicita solo cuando exista una finalidad concreta. |
| `...` (campos futuros) | **No incluir** | No se agregan campos "por si acaso"; cada nuevo campo requiere justificación. |

### 5. ¿Qué datos requerirían una justificación adicional?

| Dato | Justificación que debe presentarse |
|---|---|
| `rfc` | Solo si se emiten facturas; indicar fundamento fiscal, acceso restringido y plazo de conservación. Podría solicitarse únicamente al momento de facturar y guardarse en una tabla separada. |
| `direccion` | Solo si hay envío de productos o domicilio fiscal; definir quién la usa y por cuánto tiempo. |
| `codigo_postal` | Solo si es necesario para facturación o entrega; para analítica basta con la ciudad. |
| `telefono` | Solo si se contacta por llamada, SMS o WhatsApp; debe depender del canal elegido. |
| `fecha_nacimiento` o `rango_edad` | Solo si hay una finalidad concreta (verificar mayoría de edad, segmentación); preferir rango. |
| `nombre` | Necesario para identificar al cliente, pero debe justificarse su uso en cada área. |
| `correo` | Necesario como canal principal; si se usa para promociones, requiere consentimiento. |

### 6. ¿Cómo aplicaría privacidad por defecto?

**Principio:** la configuración inicial del sistema debe ser la más protectora, sin que el titular tenga que hacer nada. Se aplica mediante:

| Medida | Aplicación |
|---|---|
| **Recolección mínima por defecto** | Solo campos obligatorios para el servicio; los demás son opcionales o no se piden. |
| **Consentimiento desactivado por defecto** | Las finalidades secundarias (promociones, analítica) comienzan **sin consentimiento**; el cliente debe aceptarlas expresamente, sin casillas premarcadas. |
| **Datos separados por finalidad** | Datos fiscales y de entrega en tablas independientes con acceso restringido. |
| **Acceso mínimo por defecto** | Ningún rol accede a `clientes`; cada área usa vistas con los campos necesarios. |
| **Generalización y seudonimización** | Rangos de edad y región en lugar de valores exactos; uso de `id` en analítica. |
| **Enmascaramiento por defecto** | Correo y teléfono se muestran parcialmente a quienes no necesitan el valor completo. |
| **Cifrado** | Cifrado en reposo y en tránsito; cifrado de columnas sensibles como `rfc`. |
| **Retención con fecha de vencimiento** | Campos de fecha de alta y de vencimiento; procesos automáticos de eliminación o anonimización. |
| **Auditoría activada** | Registro de consultas, cambios y exportaciones desde el inicio. |
| **Límites de exportación** | Descargas masivas deshabilitadas salvo autorización. |
| **Revisión de nuevos campos** | Cada campo nuevo pasa por una revisión de privacidad antes de crearse. |

# Actividad 13 — Diferenciar controles técnicos y administrativos

| Medida | Técnico | Administrativo | Clasificación |
|---|:---:|:---:|---|
| Crear roles de PostgreSQL | X | (apoyo) | **Técnico** (con base administrativa) |
| Política de retención | (apoyo) | X | **Administrativo** (con ejecución técnica) |
| Cifrado de datos | X | | **Técnico** |
| Procedimiento para solicitudes ARCO | (apoyo) | X | **Administrativo** (con ejecución técnica) |
| Vista con información limitada | X | (apoyo) | **Técnico** (con base administrativa) |
| Clasificación de información | (apoyo) | X | **Administrativo** (con apoyo técnico) |
| Registro de auditoría | X | X | **Mixto** |
| Política de control de acceso | (apoyo) | X | **Administrativo** (se implementa técnicamente) |

### Justificación por medida

**1. Crear roles de PostgreSQL: Técnico**
Los roles (`CREATE ROLE`, `GRANT`) son un mecanismo configurado en la base de datos que obliga a cumplir los permisos. Sin embargo, qué roles crear y qué permisos asignar lo define una decisión administrativa (la política de control de acceso y la matriz de gobierno de datos). Por eso es técnico en su implementación, con origen administrativo.

**2. Política de retención: Administrativo**
Es un documento que define cuánto tiempo se conserva cada dato, con qué fundamento y qué se hace al vencer el plazo. Su cumplimiento puede automatizarse con tareas programadas de eliminación o anonimización (control técnico), pero la política en sí es una decisión organizacional.

**3. Cifrado de datos: Técnico**
Protege la confidencialidad mediante algoritmos y configuraciones (cifrado en reposo y en tránsito). Funciona aunque nadie lo recuerde o lo aplique manualmente. Tiene una parte administrativa menor (decidir qué datos cifrar y gestionar las llaves), pero la medida en sí es técnica.

**4. Procedimiento para solicitudes ARCO: Administrativo**
Define quién recibe la solicitud, cómo se valida la identidad, quién autoriza, en qué plazo se responde y cómo se documenta. Para ejecutarlo, el DBA usa consultas, un rol específico y bitácoras (parte técnica), pero el procedimiento es un proceso organizacional.

**5. Vista con información limitada: Técnico**
Es un objeto de base de datos (`CREATE VIEW`) que restringe columnas y filas. Aplica el principio de minimización de forma técnica. Qué datos debe mostrar lo determina la clasificación y la política de acceso (administrativo).

**6. Clasificación de información: Administrativo**
Consiste en definir categorías (pública, interna, confidencial, sensible) y asignar cada dato a una. Es una decisión de gobierno de datos. Puede apoyarse en etiquetas o comentarios en la base de datos (técnico), pero la clasificación es administrativa.

**7. Registro de auditoría: Mixto (técnico y administrativo)**
- **Parte técnica:** tablas de auditoría, triggers, logs de PostgreSQL (como `pgaudit`) que registran quién consultó o modificó datos, cuándo y qué valor cambió.
- **Parte administrativa:** definir qué eventos deben registrarse, quién revisa las bitácoras, con qué frecuencia, cuánto tiempo se conservan y qué se hace ante una anomalía.
- **Por qué es mixto:** un registro que nadie revisa no cumple su objetivo, y una política de revisión sin registros técnicos no tiene evidencia. Ambas partes son necesarias.

**8. Política de control de acceso: Administrativo**
Documenta quién debe tener acceso a qué y bajo qué criterios (mínimo privilegio, necesidad de saber, aprobaciones, revisiones periódicas). Se vuelve efectiva solo al implementarse técnicamente con roles, permisos, vistas y RLS.

## Análisis

**El diseño original viola la minimización y la privacidad por diseño.** La tabla recolecta datos "por si acaso" (salario, estado civil, ocupación), duplica información (`edad` y `fecha_nacimiento`), mezcla finalidades en una sola tabla y carece de llave primaria, restricciones de integridad, consentimiento y ciclo de vida. Esto aumenta la superficie de riesgo, dificulta la atención de derechos ARCO y facilita la reidentificación incluso en datos analíticos.

**Antes de aprobar un diseño hay que cuestionar cada campo.** Las preguntas sobre finalidad, necesidad, aviso de privacidad, consentimiento, sensibilidad, acceso, retención, ARCO, seguridad, terceros, menores y evaluación de riesgo permiten decidir qué datos eliminar (salario, estado civil, ocupación), cuáles sustituir (rango de edad en lugar de edad y fecha de nacimiento) y cuáles solo conservar con justificación adicional (RFC, dirección, teléfono, correo).

**La privacidad por defecto exige que la configuración inicial sea la más protectora.** Recolección mínima, consentimiento desactivado para finalidades secundarias, separación de datos por finalidad, acceso mínimo mediante vistas, generalización, enmascaramiento, cifrado, retención con vencimiento, auditoría y revisión de nuevos campos garantizan la protección sin que el titular tenga que actuar.

**Los controles técnicos y administrativos se complementan.** Los controles técnicos (roles, cifrado, vistas) hacen cumplir las reglas de forma automática, pero su configuración depende de decisiones administrativas (políticas, clasificación, procedimientos). A su vez, los controles administrativos sin implementación técnica quedan solo en papel. El registro de auditoría ejemplifica esta relación: requiere tanto la infraestructura que genera la evidencia como el proceso que la revisa.

## Conclusión

Un diseño de base de datos respetuoso con la privacidad parte de recolectar únicamente lo necesario, con finalidad definida, sin datos redundantes ni de alto riesgo, y con mecanismos de consentimiento, retención y control de acceso desde el inicio. Eliminar o sustituir datos como salario, estado civil, ocupación, edad y fecha de nacimiento reduce el impacto de una filtración y facilita el cumplimiento de los derechos ARCO.

La privacidad por defecto convierte estos principios en configuración concreta: acceso por vistas, consentimiento expreso, cifrado, enmascaramiento, retención con vencimiento y auditoría activa. Finalmente, una protección efectiva requiere **combinar controles técnicos y administrativos**: las políticas, procedimientos y clasificaciones definen qué proteger y cómo, y los mecanismos técnicos los hacen cumplir y dejan evidencia de su aplicación.