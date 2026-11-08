# Evidencia 08 — Errores y operaciones rechazadas

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 8 — Errores y operaciones rechazadas
**Fecha:** 2026-11-07

## Comandos ejecutados

```
psql "postgresql://soporte_ana:<REDACTED>@127.0.0.1/comercial" -c "DELETE FROM clientes WHERE id = 5"
```

```sql
DROP ROLE soporte_ana;   -- como administrador
```

## Resultado obtenido

```
ERROR:  permiso denegado a la tabla clientes

ERROR:  no se puede eliminar el rol «soporte_ana» porque otros objetos dependen de él
DETALLE:  privilegios para tabla clientes
```

Bitácora, ventana 21:34:12–21:34:14:

```
395 | 21:34:13.009 [14676] user=soporte_ana db=comercial app=psql client=127.0.0.1 LOG:  sentencia: DELETE FROM clientes WHERE id = 5;
396 | 21:34:13.012 [14676] user=soporte_ana db=comercial app=psql client=127.0.0.1 ERROR:  permiso denegado a la tabla clientes
397 | 21:34:13.012 [14676] user=soporte_ana db=comercial app=psql client=127.0.0.1 SENTENCIA:  DELETE FROM clientes WHERE id = 5;
402 | 21:34:13.118 [18984] user=postgres   db=comercial app=psql client=127.0.0.1 LOG:  sentencia: DROP ROLE soporte_ana;
403 | 21:34:13.120 [18984] user=postgres   ... ERROR:  no se puede eliminar el rol «soporte_ana» porque otros objetos dependen de él
404 | 21:34:13.120 [18984] user=postgres   ... DETALLE:  privilegios para tabla clientes
405 | 21:34:13.120 [18984] user=postgres   ... SENTENCIA:  DROP ROLE soporte_ana;
```

(Aquí cada sentencia aparece además como `LOG: sentencia:` porque en ese momento `log_statement = 'mod'` incluye `DELETE` y DDL. La línea `SENTENCIA:` posterior al error se debe a `log_min_error_statement = error`, que actúa con independencia de `log_statement`.)

## Respuestas

1. **¿El intento de `soporte_ana` causó algún daño? ¿Por qué debe auditarse de todos modos?**
   No: el permiso se denegó y la fila 5 no cambió. Debe auditarse porque un intento no autorizado es un indicio (cuenta mal usada, cuenta comprometida, aplicación mal configurada o una persona probando límites) y es la prueba de que el control de acceso funcionó. Si no se registra, el intento no deja huella.

2. **¿Qué diferencia hay entre un error de autorización (esta actividad) y uno de autenticación (Actividad 5)?**
   El de autenticación ocurre antes de que exista sesión (`FATAL`, el rol aún es solo un nombre declarado y la aplicación es desconocida) y falla la identidad. El de autorización ocurre dentro de una sesión ya autenticada (`ERROR`, con usuario, aplicación y cliente conocidos): la identidad es válida, pero no tiene privilegio para esa operación.

3. **¿Qué indica el error de `DROP ROLE` sobre el orden correcto para dar de baja a un usuario?**
   Que primero hay que retirar o reasignar lo que depende del rol (privilegios, objetos que posee), por ejemplo con `REVOKE …` y `REASSIGN OWNED`/`DROP OWNED`, y solo después ejecutar `DROP ROLE`. Es parte del procedimiento de baja de cuentas de la Unidad II.

## Interpretación

Los errores quedan registrados junto con la sentencia que los provocó, el usuario, la aplicación y el cliente. Dan evidencia de intentos rechazados, que son importantes aunque no hayan cambiado ningún dato.
