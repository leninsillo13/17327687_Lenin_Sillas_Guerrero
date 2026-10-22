# Evidencia 2



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

```sql
CREATE ROLE marketing NOLOGIN;
```

#### b) Vista con datos mínimos y solo clientes con consentimiento

Se asume una columna o tabla de consentimientos (por ejemplo, `acepta_promociones`):

```sql
CREATE VIEW v_marketing_promociones AS
SELECT
    id,
    correo,
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de 18'
        WHEN edad BETWEEN 18 AND 29 THEN '18-29'
        WHEN edad BETWEEN 30 AND 44 THEN '30-44'
        WHEN edad BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60 o más'
    END AS rango_edad
FROM clientes
WHERE acepta_promociones = TRUE
  AND edad >= 18;
```

#### c) Permisos limitados a la vista

```sql
GRANT USAGE ON SCHEMA public TO marketing;
GRANT SELECT ON v_marketing_promociones TO marketing;
-- NO: GRANT SELECT ON clientes TO marketing;
```

#### d) Otros controles recomendados

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

