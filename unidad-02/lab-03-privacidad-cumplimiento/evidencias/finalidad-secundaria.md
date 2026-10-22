# Evidencia 2

## Objetivo

Aplicar los principios de protección de datos personales (finalidad, consentimiento, minimización, mínimo privilegio, trazabilidad) y los derechos ARCO desde la perspectiva del administrador de base de datos (DBA), mediante tres casos prácticos:

- **Actividad 5:** analizar si una organización puede usar los datos de sus clientes para una finalidad secundaria (promociones de marketing) y qué controles técnicos deben limitar la información entregada.
- **Actividad 6:** determinar qué debe hacer la organización y el DBA al atender una solicitud de **acceso** a datos personales.
- **Actividad 7:** determinar cómo garantizar autorización y trazabilidad al atender una solicitud de **rectificación** (cambio de correo electrónico).

## Procedimiento

### Actividad 5: Finalidad secundaria

1. Se evaluó si tener los datos autoriza a usarlos para cualquier propósito, aplicando los principios de finalidad, consentimiento, información y proporcionalidad (LFPDPPP, art. 12).
2. Se elaboró una lista de preguntas previas a implementar el tratamiento (finalidad, consentimiento, necesidad, minimización, perfilado, ARCO, acceso, seguridad, retención, riesgo y menores).
3. Se revisó campo por campo la tabla `clientes` para decidir qué datos son necesarios para marketing (correo, ciudad, rango de edad, comportamiento resumido, id) y cuáles no (RFC, código postal completo).
4. Se determinó que marketing no debe tener acceso directo a `clientes`, sino a una vista con datos mínimos y solo de clientes que consintieron.
5. Se definieron controles técnicos: rol dedicado sin login directo, vista mínima, permisos limitados, seudonimización, generalización, agregación, filtro por consentimiento, Row-Level Security, enmascaramiento, auditoría, límites de exportación, retención limitada y lista de exclusión.

### Actividad 6: Derecho de acceso

1. Se identificó la información adicional que la organización debe entregar al titular junto con el resultado de la consulta: aviso de privacidad, finalidades, origen de los datos, destinatarios, plazo de conservación, áreas que acceden y cómo ejercer los demás derechos.
2. Se analizaron las implicaciones técnicas para el DBA: verificación de identidad previa, posibilidad de 0 o varios registros, localización de datos fuera de `clientes` (tablas relacionadas, respaldos, logs, exportaciones, sistemas externos), exclusión de datos agregados, uso de un rol específico para ARCO, auditoría, entrega segura y cumplimiento de plazos.

### Actividad 7: Derecho de rectificación

1. Se definieron mecanismos para comprobar que el cambio fue autorizado: validación de identidad, solicitud documentada con folio, verificación de titularidad del nuevo correo y ejecución por un rol con permisos específicos.
2. Se determinó que debe registrarse quién hizo el cambio, cuándo, el valor anterior, el nuevo y la solicitud asociada, mediante una tabla de auditoría y un trigger en PostgreSQL.
3. Se analizó la importancia de la trazabilidad.


# Actividad 5 — Analizar una finalidad secundaria

## Preguntas

### 1. ¿El hecho de que la organización ya tenga los datos significa automáticamente que puede utilizarlos para cualquier finalidad?

**No.** Tener los datos no otorga derecho a usarlos para cualquier propósito. Aplican estos principios:

- **Finalidad:** los datos solo pueden tratarse para los fines informados al titular en el aviso de privacidad (LFPDPPP, art. 12).
- **Consentimiento:** las finalidades secundarias requieren que el titular tenga la posibilidad de **negarse** o de otorgar su consentimiento, de acuerdo con el aviso de privacidad.
- **Información:** si la nueva finalidad no estaba en el aviso de privacidad, debe **actualizarse el aviso** y comunicarlo a los titulares.
- **Proporcionalidad:** solo se usan los datos necesarios para esa finalidad.

Usar los datos para algo no informado ni consentido sería un **tratamiento indebido**, aunque los datos estén almacenados legítimamente.

---

### 2. ¿Qué preguntas debería realizar la organización antes de implementar este tratamiento?

| Tema | Pregunta |
|---|---|
| **Finalidad** | ¿Esta finalidad está en el aviso de privacidad vigente? ¿Es compatible con la finalidad original? |
| **Base y consentimiento** | ¿Los titulares dieron su consentimiento o tuvieron opción de oponerse? ¿Cómo se registra? |
| **Necesidad** | ¿Se puede lograr el objetivo con menos datos o con datos agregados? |
| **Minimización** | ¿Qué datos exactos requiere marketing y por qué? |
| **Perfilado** | ¿El análisis del comportamiento de compra genera perfiles? ¿Los titulares lo esperan razonablemente? |
| **Derechos ARCO** | ¿Cómo podrá el titular acceder, rectificar, cancelar u oponerse a recibir promociones? |
| **Acceso** | ¿Quién en marketing tendrá acceso y con qué nivel? |
| **Seguridad** | ¿Qué controles protegerán los datos? ¿Se compartirán con terceros (agencias, plataformas de email)? |
| **Retención** | ¿Por cuánto tiempo se conservarán los perfiles y datos de comportamiento? |
| **Riesgo** | ¿Se necesita una evaluación de impacto en privacidad? ¿Qué pasa si hay una filtración? |
| **Menores** | ¿Se enviarán promociones a menores de edad? ¿Es apropiado? |

---

### 3. ¿Qué datos serían realmente necesarios?

| Dato | ¿Necesario? | Justificación |
|---|---|---|
| **correo** (o canal de envío) | **Sí** | Es indispensable para entregar la promoción. Solo en el momento de envío, o a través de una plataforma controlada. |
| **ciudad** | **Sí** | Permite segmentar ofertas locales. |
| **rango de edad** | **Sí** (generalizado) | Basta el rango, no la edad exacta. |
| **comportamiento de compra** | **Sí** (resumido) | Categorías de interés o frecuencia de compra, no el historial detallado. |
| **id** (o seudónimo) | **Sí** | Permite vincular segmentos sin exponer identidad. |
| nombre | Opcional | Solo si se personaliza el saludo. |
| telefono | Solo si hay SMS/WhatsApp | Depende del canal elegido. |
| **rfc** | **No** | Dato fiscal sin relación con promociones. |
| **codigo_postal** | **No** (o solo región) | Con ciudad es suficiente; el CP completo es innecesario. |
| fecha_alta | Opcional | Útil para segmentar por antigüedad, si se justifica. |

**Principio aplicado:** minimización. Se entrega lo estrictamente necesario para el objetivo.

---

### 4. ¿Necesitaría el área de marketing acceso directo a `clientes`?

**No.** Dar acceso directo a la tabla `clientes` expondría datos innecesarios (RFC, código postal, teléfono, etc.) y violaría el mínimo privilegio.

Marketing debe acceder a una **vista o tabla preparada** con solo los campos necesarios y **solo de los clientes que aceptaron recibir promociones**.

---

### 5. ¿Qué controles técnicos podrían limitar la información entregada?

#### a) Rol dedicado y sin login directo

#### b) Vista con datos mínimos y solo clientes con consentimiento

#### c) Permisos limitados a la vista

#### d) Otros controles recomendados:

| Control | Descripción |
|---|---|
| **Seudonimización** | Usar `id` o un hash en lugar de nombre o correo cuando sea posible; el envío lo hace una plataforma que resuelve el correo. |
| **Generalización** | Rangos de edad y región en lugar de valores exactos. |
| **Agregación del comportamiento** | Categorías de compra o scores, no el historial detallado. |
| **Filtro por consentimiento** | Excluir a quienes no aceptaron o se opusieron. |
| **Row-Level Security (RLS)** | Limita a nivel de fila qué registros puede ver el rol. |
| **Enmascaramiento de datos** | Ocultar parcialmente correo o teléfono cuando no se necesite completo. |
| **Auditoría y logs** | Registrar quién consulta y exporta datos. |
| **Límites de exportación** | Evitar descargas masivas sin autorización. |
| **Retención limitada** | Eliminar perfiles y datos de comportamiento tras un plazo definido. |
| **Lista de exclusión** | Respetar bajas y oposiciones de forma inmediata. |

# Actividad 6 — Derechos ARCO y la base de datos

## Preguntas

### ¿Qué información adicional debería proporcionar la organización además del resultado de esta consulta?

| Información | Por qué se entrega | Dónde se obtiene |
|---|---|---|
| **Aviso de privacidad aplicable** | El titular tiene derecho a conocer las condiciones del tratamiento. | Área de privacidad / cumplimiento |
| **Finalidades del tratamiento** | Debe saber para qué se usan sus datos (atención, facturación, analítica, marketing). | Matriz de clasificación (Actividad 1) |
| **Origen de los datos** | Si los dio él mismo o se obtuvieron de un tercero. | Documentación del proceso de captura |
| **Destinatarios** | A quién se comunican los datos (encargados, proveedores, autoridades). | Registro de transferencias y remisiones |
| **Plazo de conservación** | Cuánto tiempo se guardarán. | Política de retención (Actividad 1) |
| **Áreas que acceden** | Qué áreas tratan sus datos. | Matriz de acceso (roles y permisos) |
| **Cómo ejercer los otros derechos** | Rectificación, cancelación y oposición. | Procedimiento ARCO de la organización |

### Implicaciones técnicas para el DBA

1. **Verificar la identidad antes de consultar.** Buscar por `correo` puede devolver los datos de otra persona si alguien se hace pasar por el titular. La verificación la hace el área responsable, pero el DBA no debe ejecutar la consulta sin esa validación.

2. **La consulta puede devolver 0 o varios registros.** El correo no necesariamente es único. Conviene comparar sin importar mayúsculas (`LOWER(correo) = LOWER(...)`) y, una vez identificado el titular, trabajar con su `id`.

3. **Los datos no están solo en `clientes`.** Hay que localizar al titular en:
   - Otras tablas relacionadas por `id` (pedidos, facturas, tickets de soporte).
   - Réplicas, respaldos y archivos de logs.
   - Exportaciones (CSV, reportes) y sistemas externos (CRM, correo masivo).
   - Esto exige conocer el mapa de datos de la organización.

4. **Datos agregados.** La vista `v_analitica_clientes` no identifica al titular, por lo que normalmente no entra en la respuesta. Esa es una ventaja de haberla diseñado así.

5. **Aplicar minimización también aquí.** El DBA debe usar un rol específico para ARCO, limitado a lo necesario, y no consultar con permisos amplios.

6. **Dejar registro (auditoría).** Hay que registrar quién ejecutó la consulta, cuándo y a qué solicitud corresponde. Sirve para demostrar el cumplimiento de los plazos.

7. **Entrega segura y legible.** El resultado debe exportarse en un formato comprensible (CSV o PDF) y enviarse por un canal seguro (cifrado o con contraseña), no por correo sin protección.

8. **Cumplir los plazos.** La consulta debe poder ejecutarse con rapidez para que el área de privacidad responda dentro del plazo legal.

# Actividad 7 — Derecho de rectificación

## Preguntas

**1. ¿Cómo podría comprobarse que el cambio fue autorizado?**

- **Validando la identidad del titular** antes de ejecutar el cambio. Esa validación la hace el área responsable de privacidad (por ejemplo, con identificación oficial o confirmando desde el correo anterior).
- **Contando con una solicitud documentada**, con número de folio, fecha y medio por el que llegó (formulario, correo o ticket). El DBA ejecuta el cambio asociado a esa solicitud y no por petición verbal.
- **Confirmando la titularidad del nuevo correo**, por ejemplo enviando un enlace de verificación a `nuevo-correo@example.com`. Así se evita registrar un correo que pertenezca a un tercero.
- **Revisando que el cambio lo haya ejecutado un usuario con permisos para ello** (rol específico para solicitudes ARCO) y no cualquier usuario con acceso a la tabla.

**2. ¿Debería registrarse quién realizó el cambio?**

Sí. Debe registrarse quién lo hizo, cuándo, qué valor tenía el campo antes y cuál tiene ahora, y a qué solicitud corresponde. Una forma de hacerlo en PostgreSQL es con una tabla de auditoría y un *trigger*.

La tabla de auditoría también contiene datos personales (el correo anterior y el nuevo). Por eso debe tener acceso restringido y un plazo de conservación definido, igual que la tabla `clientes`.

**3. ¿Por qué la trazabilidad será importante?**

- **Rendición de cuentas:** permite saber quién modificó el dato y con qué autorización.
- **Evidencia de cumplimiento:** demuestra ante el titular o la autoridad que la solicitud se atendió, cuándo y en qué plazo.
- **Detección de cambios indebidos:** si alguien modifica un correo sin autorización (por ejemplo, para tomar el control de una cuenta), el registro permite detectarlo e investigarlo.
- **Posibilidad de revertir:** si hubo un error, el valor anterior queda guardado y se puede restaurar.
- **Integridad de los datos:** permite reconstruir el historial de un registro y saber cuál fue su valor en cada momento.
- **Apoyo en incidentes de seguridad:** ante una sospecha de acceso indebido, la bitácora ayuda a reconstruir lo ocurrido.

## Análisis

- **Los datos tienen una finalidad, no un dueño.** Que la organización los almacene legítimamente no significa que pueda reutilizarlos; cada uso debe estar informado y, si es secundario, ser rechazable por el titular.
- **Minimización y mínimo privilegio son los ejes técnicos.** Casi todos los controles (vistas, roles, RLS, generalización, seudonimización, enmascaramiento) buscan que cada área vea solo lo indispensable. Una vista bien diseñada, como la de analítica, además facilita el cumplimiento de ARCO porque no identifica al titular.
- **El DBA no actúa solo.** Identidad, solicitudes y respuestas legales corresponden al área de privacidad; el DBA ejecuta con rol específico, solo ante una solicitud validada y documentada, y deja evidencia.
- **Los datos están dispersos.** Un titular puede aparecer en tablas relacionadas, réplicas, respaldos, logs, exportaciones y sistemas externos, por lo que atender el acceso, la rectificación o la cancelación exige un mapa de datos actualizado. Además, el correo no es necesariamente único, por lo que se recomienda trabajar con el `id` una vez identificado el titular.
- **La trazabilidad protege a todos.** Una bitácora permite rendir cuentas, demostrar cumplimiento, detectar cambios indebidos (como la toma de control de una cuenta), revertir errores y reconstruir incidentes. Como la propia bitácora contiene datos personales, también requiere acceso restringido y retención definida.
- **Los plazos importan.** Las consultas y procesos deben poder ejecutarse con rapidez para que la organización responda dentro del plazo legal.

## Conclusión

Las tres actividades muestran que la protección de datos personales en una base de datos combina **principios jurídicos** (finalidad, consentimiento, información, proporcionalidad) con **controles técnicos concretos** (vistas mínimas, roles dedicados, seudonimización, RLS, auditoría, límites de exportación, retención limitada). El DBA es una pieza clave: no decide sobre la legitimidad de un tratamiento, pero sí puede impedir usos indebidos mediante un diseño que entregue solo lo necesario, y puede garantizar que el ejercicio de los derechos ARCO sea verificable, seguro, oportuno y auditable. En conjunto, la privacidad debe aplicarse **desde el diseño**: restringir el acceso, minimizar los datos, documentar cada solicitud y conservar evidencia de cada acción.