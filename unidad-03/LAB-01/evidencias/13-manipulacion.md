# Evidencia 13 — Intentar manipular la auditoría

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 14 — Intentar manipular la auditoría
**Fecha:** 2026-11-07

## Comandos ejecutados

Como `app_ventas`:

```
-c "DELETE FROM auditoria.cambios_clientes" -c "ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes"
```

Como administrador:

```sql
ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;
ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;
SELECT count(*) FROM auditoria.cambios_clientes;
```

## Resultado obtenido

```
ERROR:  permiso denegado al esquema auditoria
ERROR:  debe ser dueño de la tabla clientes

filas_auditoria_antes   = 3
filas_auditoria_despues = 3        <- el UPDATE del administrador no quedó en la auditoría
```

Bitácora (extracto de la ventana 21:34:27–21:34:29):

```
517 | 21:34:27.710 [11704] user=app_ventas db=comercial app=app-ventas-web client=127.0.0.1 LOG:  sentencia: DELETE FROM auditoria.cambios_clientes;
518 | 21:34:27.711 [11704] user=app_ventas ... ERROR:  permiso denegado al esquema auditoria en carácter 13
520 | 21:34:27.711 [11704] user=app_ventas ... LOG:  sentencia: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
521 | 21:34:27.712 [11704] user=app_ventas ... ERROR:  debe ser dueño de la tabla clientes
531 | 21:34:28.032 [8136]  user=postgres   db=comercial app=psql client=127.0.0.1 LOG:  sentencia: ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
532 | 21:34:28.034 [8136]  user=postgres   ... LOG:  sentencia: UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;
533 | 21:34:28.037 [8136]  user=postgres   ... LOG:  sentencia: ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;
```

El intento de `app_ventas` se registró aunque falló: con las sentencias registradas, la sentencia queda en la bitácora antes de ejecutarse.

### Discontinuidad visible en la propia auditoría

El evento 1 (21:34:27) dejó el RFC de `id = 3` en `…ZZZ`. El evento 8 (el `UPDATE` masivo de la Actividad 15, id 3) registra `valores_antes → rfc = GAMA780912GHI`. Entre ambos hubo un cambio que no está en la tabla de auditoría: el `UPDATE` hecho con el disparador desactivado.

## Respuestas

1. **¿Qué evidencia permite detectar que hubo un cambio sin auditar?**
   (a) La bitácora: las líneas 531–533 muestran la desactivación del disparador, un `UPDATE` sobre `clientes` y la reactivación, sin ningún evento nuevo en `auditoria.cambios_clientes` (el conteo siguió en 3). (b) La cadena de valores de la auditoría se rompe: el último valor registrado del RFC del cliente 3 (`ZZZ`, evento 1) no coincide con el `valores_antes` del siguiente evento (`GHI`, evento 8). (c) Comparar el número de sentencias `UPDATE`/`INSERT`/`DELETE` de la bitácora con las filas de la auditoría.

2. **¿Qué control administrativo (no técnico) reduciría este riesgo?**
   Separar funciones: quien opera la base no custodia la evidencia. Enviar las bitácoras a un sistema externo gestionado por otra área (seguridad o auditoría), exigir un procedimiento de cambios con autorización y ticket para desactivar disparadores o cambiar `log_statement`, custodiar la contraseña de `postgres` con doble control y revisar periódicamente la bitácora.

3. **Relaciona esta actividad con el principio de separación de funciones de la Unidad II.**
   En la Unidad II se separó lo que puede hacer la aplicación de lo que puede hacer el DBA: `app_ventas` no pudo borrar la auditoría ni desactivar el disparador. Pero el propio DBA es propietario del mecanismo y puede alterarlo: sin otra persona o área que custodie la evidencia, el principio no se cumple sobre el administrador.

## Interpretación

Los controles protegen la auditoría frente a la aplicación, pero no frente a quien tiene control total del servidor: el administrador desactivó el disparador y su cambio no quedó en la tabla de auditoría. Lo que queda es el rastro en la bitácora y la discontinuidad en los valores, y ambos están bajo control del mismo servidor.
