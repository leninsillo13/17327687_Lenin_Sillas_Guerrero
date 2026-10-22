# Evidencia 7

## Objetivo

Analizar un escenario integral de tratamiento de datos personales de 50,000 clientes, identificando al menos 10 problemas o riesgos y, para cada uno, el **principio de privacidad afectado**, el **riesgo** que genera y un **control propuesto**, aplicando lo trabajado en las actividades anteriores (finalidad, consentimiento, minimización, mínimo privilegio, retención, trazabilidad y ARCO).

## Procedimiento

1. Se revisó cada hecho del escenario y se contrastó con los principios de protección de datos y las buenas prácticas de administración de bases de datos.
2. Se identificó el **problema** concreto detrás de cada hecho (y los problemas derivados de combinar varios).
3. Se asoció cada problema con el **principio afectado** (finalidad, consentimiento, minimización, proporcionalidad, responsabilidad, seguridad, limitación de conservación, etc.).
4. Se describió el **riesgo** para el titular y para la organización.
5. Se propuso un **control** (técnico, administrativo o ambos) para mitigarlo.
6. Se priorizó el resultado según su gravedad.

# Actividad 14 — Escenario integral

| # | Problema | Principio afectado | Riesgo | Control propuesto |
|---|---|---|---|---|
| 1 | Analítica accede directamente a la tabla `clientes`. | Mínimo privilegio / confidencialidad | Cualquier analista ve datos que no necesita; acceso indebido, fuga interna o uso para fines distintos. | Quitar permisos sobre `clientes`; crear un rol de analítica con acceso solo a una vista (`v_analitica_clientes`). |
| 2 | Analítica ve datos identificables (nombre, correo, teléfono, RFC) aunque solo genera estadísticas mensuales. | Minimización / proporcionalidad | Exposición innecesaria de datos personales; mayor impacto ante filtración. | Vista con datos mínimos: `id` seudonimizado, rango de edad, ciudad; sin nombre, correo, teléfono, RFC ni código postal. |
| 3 | Conservación de datos durante 12 años. | Limitación de la conservación / finalidad | Datos obsoletos o innecesarios tratados sin finalidad vigente; mayor superficie de ataque y de sanción. | Revisión de los datos con más antigüedad; eliminar, bloquear o anonimizar lo que ya no sea necesario o exigible legalmente. |
| 4 | No existe política documentada de retención. | Responsabilidad (rendición de cuentas) / limitación de la conservación | Conservación indefinida de hecho; imposibilidad de demostrar cumplimiento. | Política de retención por categoría de dato, con periodo, fundamento y acción al vencer; tareas programadas de depuración. |
| 5 | Copias completas de la base para desarrolladores. | Minimización / seguridad / confidencialidad | Difusión de datos a personal que no los necesita; copias fuera del control de producción y difíciles de rastrear. | Prohibir copias completas de producción; entregar datos sintéticos, enmascarados o un subconjunto mínimo. |
| 6 | Las copias de desarrollo contienen información real. | Seguridad / finalidad | Entornos de prueba con controles débiles; filtración, pérdida de equipos o uso indebido de datos reales. | Enmascaramiento o anonimización irreversible antes de copiar a desarrollo; generación de datos de prueba ficticios. |
| 7 | Marketing usa los correos para campañas sin evidencia de finalidad ni consentimiento. | Finalidad / consentimiento / información | Tratamiento de finalidad secundaria no informada ni consentida; sanciones y quejas de titulares. | Verificar el aviso de privacidad; registrar consentimientos por finalidad; marketing solo accede a una vista de clientes con consentimiento y lista de exclusión. |
| 8 | No hay documentación clara de la finalidad de cada dato. | Finalidad / responsabilidad / transparencia | No se puede justificar el uso de cada dato ni comprobar que coincida con el aviso de privacidad. | Matriz de gobierno de datos: finalidad, responsable, usuarios autorizados, protección, retención y acción al finalizar para cada campo. |
| 9 | El RFC, el código postal y el teléfono se conservan sin justificación visible para todos los usos. | Minimización / proporcionalidad | Datos fiscales y de contacto expuestos sin necesidad funcional. | Separar datos fiscales en una tabla restringida (`clientes_facturacion`), cifrar el RFC y limitar acceso a Facturación. |
| 10 | Ausencia de controles de trazabilidad (no se menciona auditoría de consultas o exportaciones). | Responsabilidad / seguridad | No se puede saber quién consultó, copió o exportó datos; imposible detectar abusos o reconstruir un incidente. | Activar auditoría (por ejemplo, `pgaudit`), registro de consultas y exportaciones, y revisión periódica de bitácoras. |

## Análisis

- **El problema central es la falta de gobierno de datos.** Sin finalidades, responsables ni retención documentados, ninguna decisión sobre accesos o conservación puede justificarse.
- **Analítica es el mejor ejemplo de exceso de acceso.** Genera estadísticas mensuales, que no requieren identificar a nadie, pero tiene acceso a nombre, correo, teléfono y RFC. Una vista con datos seudonimizados y generalizados cumple su función con mucho menos riesgo.
- **Los datos reales en desarrollo multiplican la exposición.** Cada copia es un lugar adicional donde puede ocurrir una filtración, con controles generalmente más débiles que producción, y además complica los derechos ARCO (cancelación, acceso).
- **12 años sin política de retención implican conservación indefinida de hecho.** Es muy probable que existan clientes inactivos cuyos datos ya no son necesarios y que aun así permanecen expuestos.
- **El uso de correos por marketing es una finalidad secundaria.** Requiere estar en el aviso de privacidad y dar al titular la opción de negarse; sin documentación clara, la organización no puede demostrarlo.
- **Los problemas se agravan entre sí.** Datos excesivos, accesos amplios, copias en desarrollo y falta de retención hacen que un solo incidente afecte a 50,000 personas durante 12 años de historial.
- **Los controles técnicos y administrativos deben ir juntos.** Las vistas y roles resuelven el acceso, pero sin política, matriz de gobierno y procedimiento ARCO no se sostienen en el tiempo.

## Conclusión

El escenario presenta múltiples incumplimientos simultáneos: **acceso excesivo, datos no minimizados, copias reales en desarrollo, conservación sin límite, finalidades no documentadas y uso de correos para marketing sin evidencia de consentimiento**. Los principios más afectados son **finalidad, minimización, mínimo privilegio, limitación de la conservación y responsabilidad**. La solución combina controles técnicos (vistas restringidas, roles, seudonimización, enmascaramiento, cifrado, auditoría y límites de exportación) con controles administrativos (política de retención, matriz de gobierno de datos, aviso de privacidad, registro de consentimientos y procedimiento ARCO). Aplicados de forma conjunta, permiten que cada área acceda solo a lo que necesita, que los datos se conserven solo el tiempo justificado y que la organización pueda **demostrar cumplimiento** ante los titulares y la autoridad.