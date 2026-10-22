# Evidencia 3

## Objetivo

Comprender cómo se ejerce el **derecho de cancelación** y el **derecho de oposición** (derechos ARCO) sobre los datos personales de un titular, identificando:

- Por qué eliminar un registro de una tabla no implica que la información haya desaparecido de toda la organización (ciclo de vida del dato).
- Qué diferencia hay entre cancelar y oponerse, qué datos deben conservarse y cuáles dejan de usarse para una finalidad.
- Qué mecanismos técnicos permiten separar finalidades y por qué la decisión no debe recaer únicamente en el DBA.

## Procedimiento

**Actividad 8 — Derecho de cancelación y ciclo de vida**

1. Se realizó un análisis previo para determinar en qué lugares puede existir información del titular, revisando siete puntos: tablas relacionadas, respaldos, réplicas, registros de auditoría, copias para analítica, archivos exportados y sistemas externos.
2. Se construyó un **mapa de datos del titular**, partiendo de la tabla `clientes` y ramificando hacia todos los lugares donde sus datos pueden aparecer.
3. Se respondió la pregunta guía: *¿por qué eliminar un registro no significa que toda la información haya desaparecido?*

**Actividad 9 — Derecho de oposición**

1. Se analizó si ante una oposición es necesario eliminar inmediatamente todos los datos.
2. Se identificó qué información debe mantenerse y por qué.
3. Se identificó qué información deja de utilizarse para la finalidad a la que el titular se opuso.
4. Se definieron mecanismos técnicos para separar finalidades.
5. Se justificó por qué la decisión final no debe tomarla únicamente el DBA.

# Actividad 8 — Derecho de cancelación y ciclo de vida

## Análisis previo

| Pregunta | ¿Existe? | Qué hay que revisar |
|---|---|---|
| ¿Otras tablas relacionadas? | Sí | Pedidos, facturas, tickets de soporte, direcciones, consentimientos, vinculadas por `id`. Revisar llaves foráneas y `ON DELETE CASCADE`. |
| ¿Respaldos? | Sí | Copias completas e incrementales que contienen al titular hasta que expiren según la política de retención. |
| ¿Réplicas? | Sí | Réplicas de lectura, de alta disponibilidad y entornos de pruebas o desarrollo con copias de producción. |
| ¿Registros de auditoría? | Sí | Tabla de auditoría de rectificaciones (correo anterior y nuevo), logs de consultas y de solicitudes ARCO. |
| ¿Copias para analítica? | Sí | Vista `v_analitica_clientes`, tablas materializadas, data warehouse, datasets de BI. |
| ¿Archivos exportados? | Sí | CSV, reportes en PDF/Excel, extracciones hechas por marketing o ventas, almacenados en carpetas compartidas o correos. |
| ¿Sistemas externos? | Sí | CRM, plataforma de correo masivo, agencias de marketing, proveedores de facturación, servicios en la nube. |

## Mapa de datos del titular

```
clientes
│
├── tablas relacionadas (pedidos, facturas, tickets, consentimientos)
├── respaldos (completos, incrementales, archivados)
├── réplicas (lectura, alta disponibilidad, pruebas/desarrollo)
├── registros de auditoría (bitácora de cambios, logs de consultas, solicitudes ARCO)
├── analítica (v_analitica_clientes, data warehouse, tablas materializadas)
├── reportes
├── exportaciones (CSV, Excel, PDF)
└── sistemas externos (CRM, correo masivo, agencias, proveedores)
```

## Pregunta

**¿Por qué eliminar un registro de una tabla no necesariamente significa que toda la información relacionada con esa persona haya desaparecido de la organización?**

Porque los datos personales no viven en un solo lugar. Un `DELETE` sobre `clientes` solo elimina la fila de esa tabla en la base de datos de producción, pero el titular puede seguir existiendo en:

- **Tablas relacionadas** que referencian su `id` (pedidos, facturas, tickets).
- **Respaldos**, que conservan copias históricas hasta que se sobrescriben o expiran.
- **Réplicas y entornos de prueba**, que pueden tener copias desfasadas.
- **Bitácoras de auditoría**, que guardan valores anteriores como el correo.
- **Copias analíticas**, como data warehouses o tablas derivadas.
- **Archivos exportados** (CSV, reportes) fuera del control de la base de datos.
- **Sistemas externos** operados por terceros (CRM, plataformas de correo, agencias).

Además, algunas conservaciones son legítimas: la ley puede obligar a mantener ciertos datos durante un periodo (por ejemplo, fiscales), caso en que se **bloquean** (sin uso) hasta que concluya el plazo y luego se eliminan.

# Actividad 9 — Derecho de oposición

## Pregunta principal

**¿Es necesario eliminar inmediatamente todos sus datos de la base?**

**No.** La oposición no equivale a la cancelación. El titular no pide que se borre todo, sino que sus datos **dejen de usarse para una finalidad específica**. La relación con la organización puede continuar, por lo que los datos necesarios para las finalidades primarias (atención, entrega de productos, facturación) siguen siendo legítimos. Eliminar todo sería desproporcionado y podría afectar obligaciones legales y contractuales.

## 1. Qué información podría necesitar mantenerse

| Información | Por qué se mantiene |
|---|---|
| Datos de identificación y contacto básicos | Necesarios para la relación comercial vigente (pedidos, soporte, entregas). |
| Datos fiscales (RFC, facturas) | Obligación legal de conservación durante el plazo fiscal. |
| Historial de pedidos y transacciones | Cumplimiento contractual, garantías y obligaciones legales. |
| Tickets de soporte | Atención al cliente y seguimiento de garantías. |
| **El registro de la propia oposición** | Es indispensable para demostrar que se respetó la solicitud y evitar que el cliente reciba comunicaciones en el futuro. |
| Datos mínimos en una **lista de exclusión** | Permite identificar al titular únicamente para no volver a contactarlo. |

## 2. Qué información podría dejar de utilizarse para determinada finalidad

| Finalidad a la que se opone | Qué deja de hacerse |
|---|---|
| Promociones y marketing | Dejar de enviar correos, SMS o mensajes; excluirlo de campañas y de la vista de marketing. |
| Perfilado y análisis de comportamiento | Excluir sus datos de segmentaciones, scores y modelos de analítica. |
| Compartir con terceros con fines comerciales | Dejar de comunicar sus datos a agencias, plataformas de correo o aliados. |
| Estudios y encuestas | No incluirlo en muestras ni invitaciones. |

Los mismos datos (correo, ciudad, comportamiento de compra) **siguen existiendo** para las finalidades primarias, pero **no pueden utilizarse** para la finalidad a la que el titular se opuso.

## 3. Mecanismos técnicos para separar finalidades

| Mecanismo | Cómo ayuda |
|---|---|
| **Campo o tabla de consentimientos por finalidad** | Registrar por cliente y por finalidad (`marketing`, `analitica`, `terceros`) si aceptó, se opuso, y la fecha. Permite oponerse a una finalidad sin afectar las demás. |
| **Vistas filtradas por consentimiento** | La vista de marketing incluye únicamente clientes sin oposición; al registrarse la oposición, el cliente desaparece automáticamente de la vista. |
| **Row-Level Security (RLS)** | Limita a nivel de fila qué clientes puede ver el rol de marketing o de analítica. |
| **Roles y permisos separados** | Cada área (marketing, analítica, soporte) accede solo a las vistas de su finalidad. |
| **Lista de exclusión (supresión)** | Tabla mínima con id o hash del correo de quienes se opusieron; se consulta antes de cada envío o campaña. |
| **Seudonimización** | En analítica, reemplazar identificadores por seudónimos y excluir al titular opuesto. |
| **Propagación a sistemas externos** | Sincronizar la oposición con CRM y plataformas de correo (baja o suppression list). |
| **Auditoría** | Registrar quién, cuándo y bajo qué folio se aplicó la oposición. |
| **Bloqueo en procesos automáticos** | Validaciones en los procesos de ETL y envío que excluyan a quienes tengan la oposición vigente. |

## 4. Por qué la decisión final no debe ser tomada únicamente por el DBA

- **Competencia legal.** Determinar si la oposición procede, a qué finalidades alcanza y qué datos deben conservarse por obligación legal corresponde al área de privacidad o legal, no al DBA.
- **Verificación de identidad.** El DBA no debe actuar sin que el área responsable haya validado al solicitante.
- **Conocimiento del negocio.** Solo las áreas de negocio saben qué procesos usan los datos y qué impacto tendría la oposición (marketing, ventas, analítica).
- **Excepciones legales.** Pueden existir finalidades que no admiten oposición (obligaciones fiscales, contractuales o de autoridad) y requieren criterio jurídico.
- **Alcance más allá de la base de datos.** La oposición afecta sistemas externos, proveedores y procesos que el DBA no controla.
- **Separación de funciones y rendición de cuentas.** Si una sola persona decide y ejecuta, no hay control cruzado. Lo correcto es que la decisión se documente, se autorice y el DBA ejecute con un rol específico, dejando evidencia.
- **Riesgo de error.** Una decisión técnica aislada podría borrar datos que deben conservarse o dejar activos usos que debieron cesar.

## Análisis

**Por qué un `DELETE` no elimina todo (Actividad 8).** Un `DELETE` sobre `clientes` solo borra la fila en la base de producción. Los datos personales no viven en un solo lugar: pueden permanecer en tablas relacionadas, respaldos, réplicas, bitácoras de auditoría, copias analíticas, archivos exportados y sistemas externos operados por terceros. Además, algunas conservaciones son legítimas: la ley puede exigir mantener ciertos datos (por ejemplo, fiscales), en cuyo caso se **bloquean** (sin uso) hasta que concluya el plazo y luego se suprimen.

**Oposición no es cancelación (Actividad 9).** No es necesario eliminar inmediatamente todos los datos. El titular no pide que se borre todo, sino que sus datos dejen de usarse para una finalidad específica. La relación con la organización puede continuar, por lo que los datos necesarios para las finalidades primarias (atención, entrega, facturación) siguen siendo legítimos. Los mismos datos siguen existiendo, pero no pueden usarse para la finalidad a la que el titular se opuso. Eliminar todo sería desproporcionado y podría afectar obligaciones legales y contractuales.

**Por qué la decisión no debe ser solo del DBA:**

- **Competencia legal:** determinar si la oposición procede y qué datos conservar corresponde al área de privacidad o legal.
- **Verificación de identidad:** el DBA no debe actuar sin que el área responsable valide al solicitante.
- **Conocimiento del negocio:** solo las áreas de negocio conocen el impacto en marketing, ventas y analítica.
- **Excepciones legales:** hay finalidades que no admiten oposición y requieren criterio jurídico.
- **Alcance más allá de la base de datos:** afecta sistemas externos y proveedores que el DBA no controla.
- **Separación de funciones:** si una persona decide y ejecuta, no hay control cruzado; lo correcto es documentar, autorizar y que el DBA ejecute con un rol específico, dejando evidencia.
- **Riesgo de error:** una decisión técnica aislada podría borrar datos que deben conservarse o dejar activos usos que debieron cesar.

## Conclusión

El ejercicio de los derechos de cancelación y oposición va mucho más allá de ejecutar una sentencia SQL. El ciclo de vida de los datos personales abarca tablas relacionadas, respaldos, réplicas, auditoría, analítica, exportaciones y terceros, por lo que cumplir una cancelación exige un **mapa de datos** que permita localizar y tratar la información en todos esos puntos, respetando los plazos legales de conservación (bloqueo y posterior supresión).

En el caso de la oposición, lo correcto no es borrar, sino **dejar de usar** los datos para la finalidad rechazada, conservando lo necesario para las finalidades primarias y las obligaciones legales. Esto se logra con mecanismos técnicos como consentimientos por finalidad, vistas filtradas, RLS, listas de exclusión, seudonimización y propagación a sistemas externos, siempre con auditoría.