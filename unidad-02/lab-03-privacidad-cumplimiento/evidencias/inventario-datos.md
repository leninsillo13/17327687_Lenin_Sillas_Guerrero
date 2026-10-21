# Actividad 1 — Inventario y finalidad de los datos

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

