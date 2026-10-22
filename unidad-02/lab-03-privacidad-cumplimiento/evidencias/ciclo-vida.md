# Evidencia 3

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
