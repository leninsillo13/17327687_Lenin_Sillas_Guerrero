# Evidencia 8

## Objetivo

Diseñar una propuesta conceptual de arquitectura de base de datos que **separe la información de acuerdo con su finalidad** (operación, analítica y auditoría), incorporando controles de acceso, minimización, protección de información sensible, retención, trazabilidad, eliminación y atención de solicitudes ARCO. El propósito es demostrar que los principios de privacidad (finalidad, minimización, mínimo privilegio, limitación de la conservación y responsabilidad) pueden traducirse en decisiones técnicas concretas, sin necesidad de implementar físicamente toda la arquitectura.

## Procedimiento

1. Se identificaron las finalidades principales del tratamiento: **operación** (atender y facturar), **analítica** (estadísticas) y **auditoría** (evidencia y trazabilidad).
2. Se asignó a cada finalidad un espacio lógico separado (esquema o base de datos) con los datos estrictamente necesarios.
3. Se definieron los flujos permitidos entre espacios (por ejemplo, operación hacia analítica solo mediante un proceso que agrega y seudonimiza).
4. Se agregaron los siete controles solicitados a cada capa.
5. Se tradujo cada decisión a un mecanismo técnico concreto en PostgreSQL (esquemas, roles, vistas, RLS, triggers, cifrado, tareas programadas).

# Actividad 15 — Propuesta de arquitectura de datos protegidos

## Resultado

### 1. Arquitectura conceptual

```
                          BASE DE DATOS
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
   OPERACIÓN               ANALÍTICA              AUDITORÍA
 (esquema: operacion)   (esquema: analitica)   (esquema: auditoria)
        │                      │                      │
        ▼                      ▼                      ▼
 Datos necesarios         Datos agregados        Bitácoras de acceso,
 para operación           y seudonimizados       cambios y solicitudes
        │                      ▲                      ▲
        │   proceso ETL        │                      │
        └──(agrega y──────────►┘                      │
            seudonimiza)                              │
        │                                             │
        └──────── triggers y registro de eventos ────►┘
```

### 2. Detalle de cada capa

#### Capa de Operación (esquema `operacion`)

**Finalidad:** atención al cliente, entrega de servicios y facturación.

| Tabla | Contenido | Finalidad |
|---|---|---|
| `clientes` | `id`, nombre, correo, teléfono, ciudad, `fecha_alta`, `fecha_retencion` | Identificación y contacto |
| `clientes_facturacion` | `id_cliente`, RFC (cifrado), código postal | Obligación fiscal |
| `consentimientos` | `id_cliente`, finalidad, estatus, fecha, folio | Registro por finalidad |
| `lista_exclusion` | hash del correo, fecha, folio | Respetar oposiciones |

#### Capa de Analítica (esquema `analitica`)

**Finalidad:** estadísticas mensuales sin identificar personas.

| Objeto | Contenido |
|---|---|
| `v_analitica_clientes` | seudónimo (hash del `id`), rango de edad, ciudad o región, categorías de compra |
| `estadisticas_mensuales` | totales y promedios agregados por región y rango de edad |

No contiene nombre, correo, teléfono, RFC ni código postal.

#### Capa de Auditoría (esquema `auditoria`)

**Finalidad:** rendición de cuentas y evidencia de cumplimiento.

| Tabla | Contenido |
|---|---|
| `bitacora_cambios` | quién, cuándo, tabla, valor anterior y nuevo, folio |
| `bitacora_accesos` | quién consultó o exportó, cuándo y desde dónde |
| `solicitudes_arco` | folio, tipo de derecho, fecha, estatus, responsable, resultado |

### 3. Controles por tema

| Control | Operación | Analítica | Auditoría |
|---|---|---|---|
| **Acceso** | Roles `rol_atencion`, `rol_facturacion`; acceso mediante vistas, no a tablas base. | Rol `rol_analitica` solo sobre `v_analitica_clientes`. | Solo `rol_auditor` y `rol_privacidad`, en solo lectura. Nadie puede modificar o borrar bitácoras. |
| **Minimización** | Solo campos necesarios por finalidad; datos fiscales en tabla aparte. | Seudónimos, rangos de edad y región; sin identificadores directos. | Registrar identificadores y tipo de acción; evitar copiar valores sensibles completos. |
| **Protección de información sensible** | Cifrado de RFC (por ejemplo, `pgcrypto`), enmascaramiento de correo y teléfono, TLS en tránsito. | Cohortes mínimas (por ejemplo, no publicar grupos de menos de 10 personas) para evitar reidentificación. | Enmascarar o aplicar hash a valores sensibles en la bitácora; acceso restringido. |
| **Retención** | Campo `fecha_retencion`; datos de contacto durante la relación; datos fiscales durante el plazo legal. | Datos agregados con plazo definido; detalle seudonimizado con retención corta. | Plazo propio definido por la política (por ejemplo, el necesario para demostrar cumplimiento). |
| **Trazabilidad** | Triggers que registran cambios en `bitacora_cambios`. | Registro de consultas y de ejecuciones del proceso ETL. | Bitácoras inmutables (solo `INSERT`), con respaldo separado. |
| **Eliminación** | Tarea programada que elimina, bloquea o anonimiza al vencer la retención. | Regeneración periódica de datos derivados; se excluye a quienes cancelaron u se opusieron. | Eliminación o seudonimización al vencer su plazo; se conserva solo la evidencia mínima. |
| **Atención de solicitudes** | Rol `rol_arco` para localizar y ejecutar acceso, rectificación, cancelación y oposición por `id`. | Excluir al titular en la siguiente carga; no se identifica en agregados. | Cada solicitud queda registrada con folio, fecha y responsable. |

## Análisis

- **Separar por finalidad reduce el riesgo por diseño.** Cada área solo llega al espacio que corresponde a su función; una vulneración en analítica no expone RFC ni datos de contacto.
- **La analítica no necesita identificar personas.** Con seudónimos, rangos y agregados se cumple el objetivo estadístico y desaparece el acceso a datos identificables.
- **La auditoría es independiente de la operación.** Al aislarla y hacerla de solo inserción, quien opera los datos no puede borrar la evidencia de lo que hizo.
- **Los flujos controlados evitan la fuga entre finalidades.** El ETL es el único puente, y es ahí donde se aplican la minimización, el consentimiento y las exclusiones.
- **La eliminación y las solicitudes ARCO se simplifican.** Con un mapa claro de dónde vive cada dato, atender cancelación u oposición implica actuar sobre capas conocidas y no buscar copias dispersas.
- **La auditoría también contiene datos personales.** Por eso requiere acceso restringido, enmascaramiento y su propio plazo de retención.
- **Limitaciones de la propuesta.** Es conceptual: faltan definir los plazos legales exactos, la gestión de llaves de cifrado, el tratamiento de respaldos y réplicas, y la sincronización con sistemas externos. Deben resolverse con las áreas legal, privacidad y seguridad.

## Conclusión

La propuesta demuestra que los principios de privacidad pueden traducirse en decisiones técnicas concretas: **esquemas separados por finalidad** (finalidad), **vistas y datos seudonimizados** (minimización), **roles y permisos por función** (mínimo privilegio), **cifrado y enmascaramiento** (protección de información sensible), **fechas de retención y tareas de depuración** (limitación de la conservación), **bitácoras inmutables** (trazabilidad) y **un rol y registro específicos para ARCO** (atención de solicitudes). Separar operación, analítica y auditoría limita el alcance de cualquier incidente, facilita demostrar cumplimiento y permite que cada dato exista solo donde tiene una finalidad justificada y solo mientras sea necesario.

# Verificación final

### 1. Privacidad: ¿qué diferencia existe entre seguridad de la información y privacidad?

- **Seguridad de la información** protege los datos contra accesos no autorizados, pérdida, alteración o destrucción. Busca garantizar **confidencialidad, integridad y disponibilidad**. Pregunta clave: *¿cómo evito que personas no autorizadas accedan a los datos o los dañen?*
- **Privacidad** se refiere a cómo se **recolectan, usan, comparten y conservan** los datos personales, y al derecho del titular a decidir sobre ellos. Pregunta clave: *¿la organización tiene derecho a tratar estos datos, para qué y por cuánto tiempo?*

| Aspecto | Seguridad | Privacidad |
|---|---|---|
| Enfoque | Proteger los datos | Tratar legítimamente los datos |
| Amenaza principal | Atacantes, errores, fallas | Uso indebido, incluso por quien tiene acceso legítimo |
| Ejemplos de control | Cifrado, firewall, respaldos, autenticación | Aviso de privacidad, consentimiento, minimización, ARCO |
| Alcance | Todo tipo de información | Datos de personas identificables |

### 2. Finalidad: ¿por qué una organización no debería utilizar automáticamente todos los datos que posee para cualquier propósito?

Porque **tener los datos no otorga derecho a usarlos para cualquier fin**. Los datos se recabaron para finalidades informadas al titular en el aviso de privacidad, y solo para ellas existe una base legítima de tratamiento.

- **Expectativa razonable del titular:** quien da su correo para recibir una factura no espera ser incluido en campañas de marketing o en perfiles de comportamiento.
- **Marco legal:** las finalidades secundarias requieren que el titular pueda negarse o dar su consentimiento (LFPDPPP).
- **Confianza:** usar los datos fuera de lo informado erosiona la relación con los clientes.
- **Riesgo legal:** tratamiento indebido, sanciones y quejas ante la autoridad.
- **Control técnico:** se separan finalidades con consentimientos por finalidad, vistas filtradas y roles distintos.

### 3. Minimización: ¿por qué almacenar más información no necesariamente es mejor?

Porque cada dato adicional trae **costos y riesgos** sin un beneficio demostrado:

- **Mayor impacto ante una filtración** (salario, estado civil, fecha de nacimiento ampliarían el daño).
- **Mayor superficie de ataque** y más cosas que proteger.
- **Más dificultad para atender ARCO**, porque hay más copias que localizar.
- **Datos obsoletos o inexactos**, que degradan la calidad de la información.
- **Costos operativos:** almacenamiento, respaldos, réplicas y administración.
- **Riesgo de reidentificación** al combinar datos aparentemente inocuos.
- **Incumplimiento legal:** los datos deben ser los necesarios, adecuados y proporcionales a la finalidad.

### 4. ARCO: ¿qué implicaciones técnicas tienen los derechos de acceso, rectificación, cancelación y oposición?

| Derecho | Implicaciones técnicas |
|---|---|
| **Acceso** | Verificar identidad antes de consultar; localizar al titular en todas las tablas, respaldos, logs, exportaciones y sistemas externos; el correo puede no ser único (trabajar con `id`); entregar el resultado en formato legible y por canal seguro; usar un rol ARCO limitado; registrar quién consultó y cuándo. |
| **Rectificación** | Solicitud documentada con folio; validar identidad y titularidad del nuevo dato; ejecutar con rol autorizado; tabla de auditoría con trigger que guarde valor anterior, valor nuevo, usuario, fecha y folio; propagar el cambio a copias y sistemas externos. |
| **Cancelación** | Analizar tablas relacionadas, respaldos, réplicas, analítica, exportaciones y sistemas externos antes de ejecutar un `DELETE`; distinguir entre eliminar, **bloquear** (datos con obligación legal) y anonimizar; documentar el plazo de expiración de respaldos; notificar a terceros. |
| **Oposición** | No implica borrar todo, sino **dejar de usar** los datos para una finalidad específica; requiere consentimientos por finalidad, vistas filtradas, lista de exclusión, RLS y propagación a CRM y plataformas de correo. |

### 5. Retención: ¿por qué la conservación indefinida puede representar un riesgo?

- **Seguridad:** más datos y por más tiempo aumentan el impacto de una filtración, incluso de clientes inactivos.
- **Legal:** tratar datos sin finalidad vigente contraviene la minimización y la limitación de la conservación.
- **Operativo y económico:** crecen las bases, los respaldos y las réplicas, con costos y mayores tiempos de recuperación.
- **Calidad:** los datos envejecen (correos, teléfonos y domicilios dejan de ser correctos).
- **ARCO:** hay más copias que buscar y cancelar.
- **Reputacional:** una filtración de datos antiguos e innecesarios es difícil de justificar ante clientes y autoridades.
- **Uso indebido:** datos disponibles "por si acaso" favorecen finalidades no informadas.

### 6. Gobierno: ¿quién debería decidir qué datos pueden utilizarse y para qué finalidad?

La decisión **no corresponde a una sola persona o área**, sino a una estructura de gobierno de datos:

| Actor | Papel en la decisión |
|---|---|
| **Dirección / alta gerencia** | Aprueba políticas y asigna recursos y responsabilidades. |
| **Área de privacidad / cumplimiento / legal** | Determina la licitud, el aviso de privacidad, el consentimiento, los plazos legales y la procedencia de las solicitudes ARCO. |
| **Dueños de los datos (áreas de negocio)** | Justifican la necesidad funcional del dato y para qué lo usan. |
| **Seguridad de la información** | Define y verifica los controles de protección. |
| **DBA / TI** | Implementa técnicamente las decisiones (roles, vistas, auditoría, retención). |
| **Titular** | Informa, consiente, se opone o ejerce sus derechos. |

### 7. DBA: ¿cuál es su responsabilidad y cuáles decisiones deben involucrar a otras áreas?

**Responsabilidad del DBA (custodio técnico, no dueño de los datos):**

- Implementar roles, permisos, vistas, RLS y principio de mínimo privilegio.
- Aplicar cifrado, enmascaramiento y seudonimización.
- Configurar auditoría y trazabilidad.
- Ejecutar retención, eliminación o anonimización según la política aprobada.
- Ejecutar solicitudes ARCO validadas, con un rol específico y dejando evidencia.
- Gestionar respaldos, réplicas y entornos de prueba (datos enmascarados o sintéticos).
- Alertar sobre riesgos y proponer mejoras técnicas.

**Decisiones que deben involucrar a otras áreas:**

| Decisión | Quién debe participar |
|---|---|
| Qué finalidad es legítima y si requiere consentimiento | Privacidad / legal |
| Si una solicitud ARCO procede y qué datos se conservan | Privacidad / legal |
| Verificación de identidad del solicitante | Área responsable de privacidad |
| Qué datos necesita cada área y para qué | Dueños de datos / negocio |
| Plazos de retención | Legal, fiscal, negocio y privacidad |
| Compartir datos con terceros | Legal, privacidad y dirección |
| Aprobación de nuevas recolecciones o campos | Privacidad y negocio |
| Tratamiento tras un incidente de seguridad | Seguridad, legal y dirección |