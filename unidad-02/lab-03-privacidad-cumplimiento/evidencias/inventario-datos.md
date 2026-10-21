# Actividad 1 — Inventario y finalidad de los datos
## Matriz de clasificación de datos

| Campo | ¿Es dato personal? | Finalidad | ¿Es necesario? | Nivel de acceso | Retención |
|---|---|---|---|---|---|
| id | Sí (indirecto): es un identificador único que, al vincularse con otros campos, permite identificar a la persona. | Identificar de forma única cada registro y relacionar tablas. | Sí | Interno: personal técnico y sistemas autorizados. | Durante la relación con el titular y hasta su baja. |
| nombre | Sí (identificativo directo) | Identificar al titular, personalizar la atención y emitir comprobantes. | Sí | Atención a clientes, ventas y administración. | Durante la relación con el titular + plazo legal aplicable (p. ej. 5 años por obligaciones fiscales). |
| correo | Sí (contacto) | Enviar confirmaciones, notificaciones y comunicaciones del servicio; recuperación de cuenta. | Sí | Atención a clientes y marketing (solo con consentimiento para promociones). | Durante la relación con el titular; se elimina al cancelar la cuenta o a solicitud del titular. |
| telefono | Sí (contacto) | Contacto alternativo para aclaraciones, entregas o seguimiento. | No (opcional) | Atención a clientes y logística. | Durante la relación con el titular; se elimina al cancelar o a solicitud. |
| rfc | Sí (identificativo y fiscal; permite inferir fecha de nacimiento y datos de identidad) | Emitir facturas (CFDI) y cumplir obligaciones fiscales. | Condicional: solo si el cliente solicita factura. | Restringido: finanzas y contabilidad. | 5 años como mínimo, conforme a la normativa fiscal (CFF). |
| edad | Sí (característica personal) | Segmentación general o verificación de mayoría de edad, si el servicio lo exige. | No, salvo que exista restricción legal de edad. | Restringido: analítica y cumplimiento. | Mientras sea útil para la finalidad; preferible anonimizar o agregar. |
| ciudad | Sí (dato de ubicación, de bajo riesgo por sí solo) | Calcular envíos, ofrecer servicios locales y hacer estadísticas regionales. | No (opcional) | Logística, ventas y analítica. | Durante la relación con el titular o hasta cumplir la finalidad (p. ej. entrega). |
| codigo_postal | Sí (dato de ubicación; combinado con otros campos aumenta la identificabilidad) | Calcular costos y cobertura de envío; domicilio fiscal en facturación. | Condicional: solo si hay envíos o facturación. | Logística y finanzas. | Durante la relación con el titular; si es domicilio fiscal, 5 años. |
| fecha_alta | No por sí sola (dato de registro del sistema); pasa a ser personal al asociarse con un titular identificado. | Auditoría, antigüedad del cliente y control de ciclo de vida del registro. | Sí | Interno: administración y soporte técnico. | Durante la relación con el titular + plazo de conservación para auditoría o defensa legal. |

# Actividad 2 — Principio de minimización

## Preguntas

### 1. ¿Todos los campos son necesarios para atención al cliente?

**No.** Soporte solo necesita **identificar** al cliente y **contactarlo**. Por eso bastan estos campos:

| Campo | ¿Necesario? | Motivo |
|---|---|---|
| id | Sí | Vincula el caso con el registro original. |
| nombre | Sí | Identifica y dirige la atención al cliente. |
| correo | Sí | Canal principal de comunicación. |
| telefono | Sí (opcional) | Contacto alternativo para dar seguimiento. |
| rfc | **No** | Es un dato fiscal, ajeno a la atención. |
| edad | **No** | No influye en resolver una incidencia. |
| ciudad | **No** | No se requiere para dar soporte. |
| codigo_postal | **No** | No se requiere para dar soporte. |
| fecha_alta | **No** | Es un metadato administrativo, no operativo. |

### 2. ¿Por qué soporte necesitaría conocer el RFC?

**Normalmente no lo necesita.** El RFC sirve para facturación y obligaciones fiscales, que son responsabilidad de finanzas o contabilidad. Además, es un dato de **alto riesgo**: permite inferir la fecha de nacimiento y facilita fraudes y suplantación de identidad. Si soporte lo tuviera, aumentaría innecesariamente la superficie de exposición. Si en algún caso puntual se requiere (por ejemplo, una aclaración sobre una factura), debe canalizarse al área fiscal o consultarse bajo un acceso controlado y registrado.

### 3. ¿Necesita conocer la edad?

**No.** Resolver una incidencia, responder una duda o dar seguimiento a un pedido no depende de la edad del cliente. Recolectarla sin una finalidad clara viola la proporcionalidad. Solo se justificaría si existiera una restricción legal por edad, y aun así bastaría un indicador (mayor de edad: sí/no).

### 4. ¿Necesita conocer el código postal?

**No, en general.** El soporte se brinda por correo o teléfono y no requiere ubicar geográficamente al cliente. Es un dato que, combinado con nombre y edad, puede facilitar la **reidentificación** de una persona. Solo sería necesario si el soporte incluyera logística (por ejemplo, seguimiento de envíos), y en ese caso debería limitarse a ese equipo específico.

### 5. ¿Qué principio de privacidad está relacionado con esta decisión?

El principio de **minimización de datos**, junto con el de **proporcionalidad** (LFPDPPP, art. 13): solo deben tratarse los datos personales **necesarios, adecuados y relevantes** para la finalidad. También se relacionan:

- **Finalidad:** los datos se usan solo para el propósito informado al titular.
- **Mínimo privilegio:** cada área accede solo a lo que necesita.
- **Privacidad desde el diseño:** la restricción se aplica desde la estructura de la tabla, no después.

# Actividad 3 — Separación por finalidad

## Pregunta

### ¿Por qué esta información puede ser más apropiada para analítica que entregar directamente la tabla completa de clientes?

Porque la información agregada cubre la necesidad de analítica **sin exponer datos personales de individuos**. Las razones principales son:

1. **Minimización de datos:** analítica solo necesita saber *cuántos* clientes hay por ciudad o rango de edad, no *quiénes* son. Entregar nombre, correo, teléfono y RFC excedería la finalidad (principio de proporcionalidad).

2. **Separación por finalidad:** los datos se recabaron para operar el servicio. Usarlos con fines estadísticos debe hacerse con el mínimo de información necesaria, sin arrastrar datos identificativos.

3. **Reducción de riesgo:** si el resultado se filtra o se usa indebidamente, no hay forma de contactar, identificar ni suplantar a ningún cliente. Una tabla completa expondría datos de alto riesgo como el RFC.

4. **Menor posibilidad de reidentificación:** al generalizar la edad en rangos y agrupar por ciudad, ningún registro individual es visible. Los datos agregados son mucho más difíciles de vincular con una persona concreta.

5. **Mínimo privilegio:** cada área accede solo a lo que necesita para su función. Analítica trabaja con estadísticas; soporte, con datos de contacto; finanzas, con datos fiscales.

6. **Cumplimiento normativo:** reduce la obligación y el alcance del tratamiento de datos personales (LFPDPPP), ya que la información agregada y anonimizada deja de permitir identificar al titular.

7. **Mejor calidad analítica:** la consulta ya entrega los datos listos para interpretar (conteos y segmentos), sin que el analista tenga que manipular información sensible.

