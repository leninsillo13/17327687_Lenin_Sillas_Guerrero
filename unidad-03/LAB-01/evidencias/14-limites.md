# Evidencia 14 — Límites: lecturas y volumen

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 15 — Límites: lecturas y volumen
**Fecha:** 2026-11-07

## Comandos ejecutados

```
psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial" -c "SELECT nombre, rfc, telefono FROM clientes WHERE id = 3"
```

```sql
UPDATE clientes SET segmento = 'regular';   -- como administrador, sin WHERE

SELECT count(*) AS lineas_bitacora FROM dba.bitacora WHERE linea LIKE '%sentencia: UPDATE clientes SET segmento%';
SELECT operacion, count(*) FROM auditoria.cambios_clientes GROUP BY operacion ORDER BY operacion;
SELECT count(*) AS lecturas_soporte FROM dba.bitacora WHERE linea LIKE '%user=soporte_ana%SELECT nombre, rfc%';
```

## Resultado obtenido

```
 lineas_bitacora
-----------------
               1

 operacion | count
-----------+-------
 DELETE    |     1
 INSERT    |     1
 UPDATE    |     6

 lecturas_soporte
------------------
                0
```

Bitácora de `soporte_ana` en 21:34:31: solo `conexión autenticada` (544), `conexión autorizada` (545) y `desconexión` (546). La consulta del RFC (que devolvió `María García | GAMA780912GHI | 6679990000`) no aparece. El `UPDATE` masivo: una línea, la 550.

- El `UPDATE` masivo produjo **1 línea** en la bitácora y **5 filas nuevas** en la auditoría (eventos 4–8; los 6 UPDATE en total son el del incidente más estos 5).
- La lectura del RFC no dejó rastro: no hay disparador para `SELECT` y `mod` no registra consultas.

## Respuestas

1. **Si `clientes` tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un `UPDATE` sin `WHERE`?**
   La bitácora seguiría teniendo una línea, pero la tabla de auditoría recibiría un millón de filas, cada una con el registro antes y después en JSONB (el doble del contenido de cada fila). La transacción tardaría más, crecerían tabla, índices, WAL y respaldos, y la consulta de la auditoría se volvería costosa. Habría que particionarla, definir su retención y, quizá, usar disparadores por sentencia o controlar quién puede hacer actualizaciones masivas.

2. **Propón quién podría autorizar la depuración de `auditoria.cambios_clientes`.**
   Un responsable distinto del DBA operador: el responsable de seguridad de la información o de auditoría interna, con el responsable del dato (negocio) y el área de cumplimiento/privacidad, según la política de retención aprobada. El DBA ejecutaría la depuración solo con esa autorización documentada.

3. **¿Por qué `log_statement = 'all'` puede convertir la bitácora en un nuevo depósito de datos sensibles?**
   Porque registra el texto de todas las consultas, incluidos los valores literales (RFC, teléfonos, correos, contraseñas) escritos en ellas, de todas las tablas y usuarios. La bitácora pasa a ser una copia de datos sensibles con menos controles que la base: archivos, exportaciones, respaldos, herramientas de análisis.

## Alternativas para registrar lecturas

| Alternativa | Ventaja | Desventaja |
|---|---|---|
| `log_statement = 'all'` | No requiere instalar nada | Registra todas las consultas de todas las tablas |
| Entregar el dato solo mediante una función que registre su uso | Control preciso | Requiere cambiar la aplicación |
| pgaudit con auditoría de objeto (Parte C, **no realizada**) | Registra lecturas por tabla y por columna | Requiere instalar una extensión |

## Interpretación

La bitácora y el disparador se complementan, pero ninguno cubre las lecturas con la configuración elegida (`mod`): `soporte_ana` pudo leer el RFC sin dejar rastro. El `UPDATE` masivo muestra la diferencia entre registrar la sentencia (1 línea) y registrar el dato (5 filas).
