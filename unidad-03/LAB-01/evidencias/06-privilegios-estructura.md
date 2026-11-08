# Evidencia 06 — Cambios de privilegios y de estructura

**Estudiante:** Lenin Sillas Guerrero
**Actividad:** 6 — Cambios de privilegios y de estructura
**Fecha:** 2026-11-07

## Comandos ejecutados

Ver `sql/03-privilegios-estructura.sql`. Con `log_statement = 'ddl'`, como administrador:

```sql
REVOKE UPDATE ON clientes FROM soporte_ana;
GRANT UPDATE ON clientes TO app_ventas;
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);

CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';
DROP ROLE rol_temporal;
```

## Resultado obtenido

Todas las sentencias terminaron sin error (`REVOKE`, `GRANT`, `ALTER TABLE`, `CREATE ROLE`, `DROP ROLE`). Bitácora, ventana 21:33:59–21:34:01

```
348 | 2026-11-07 21:33:59.863 CST [10948] user=postgres db=comercial app=psql client=127.0.0.1 LOG:  sentencia: REVOKE UPDATE ON clientes FROM soporte_ana;
349 | 2026-11-07 21:33:59.865 CST [10948] user=postgres db=comercial app=psql client=127.0.0.1 LOG:  sentencia: GRANT UPDATE ON clientes TO app_ventas;
350 | 2026-11-07 21:33:59.867 CST [10948] user=postgres db=comercial app=psql client=127.0.0.1 LOG:  sentencia: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
355 | 2026-11-07 21:34:00.091 CST [20924] user=postgres db=comercial app=psql client=127.0.0.1 LOG:  sentencia: CREATE ROLE rol_temporal LOGIN PASSWORD '<REDACTED>';
356 | 2026-11-07 21:34:00.103 CST [20924] user=postgres db=comercial app=psql client=127.0.0.1 LOG:  sentencia: DROP ROLE rol_temporal;
```

### La bitácora filtró un secreto

La línea 355 contenía la contraseña del rol temporal **en texto claro** y eliminar el rol no la borra del archivo. Aquí y en el archivo exportado (`bitacora-lab01.log`) está sustituida por `<REDACTED>`.

La contraseña de `app_ventas` y `soporte_ana` no quedó en la bitácora porque el script de preparación fijó `log_statement = 'none'` en esa sesión antes de ejecutar `ALTER ROLE … PASSWORD`. (La guía usa `\password`, que envía solo el resumen SCRAM.)

## Respuestas

1. **¿Qué tipo de evento es cada una de las tres primeras sentencias (privilegio o estructura)?**
   `REVOKE UPDATE …` → **privilegio**. `GRANT UPDATE …` → **privilegio**. `ALTER TABLE … ADD COLUMN` → **estructura**. El `CREATE ROLE`/`DROP ROLE` también son de privilegio (gestión de roles). Las tres primeras se ejecutaron en la misma sesión (PID 10948).

2. **¿Por qué `GRANT` y `REVOKE` quedan registrados con `log_statement = 'ddl'`?**
   Porque `ddl` registra todas las sentencias que definen o cambian objetos y sus permisos: `CREATE`, `ALTER`, `DROP`, y también `GRANT`, `REVOKE` y `COMMENT`.

3. **Si la bitácora contiene contraseñas, ¿quién debería poder leerla? Relaciónalo con la gestión de secretos de la Unidad II.**
   Solo el administrador o un rol de auditoría, con permisos del sistema de archivos restringidos, y debe tratarse con la misma clasificación que un secreto. Siguiendo la gestión de secretos de la Unidad II, las contraseñas no deben escribirse en sentencias SQL (usar `\password` o un gestor de secretos), y si una contraseña real llegó a la bitácora hay que rotarla aunque el rol se haya eliminado.

## Interpretación

Los cambios de privilegios y de estructura quedan con quién (`postgres`), cuándo, desde dónde (`127.0.0.1`, `psql`) y qué sentencia. El mismo mecanismo que da la evidencia también expone secretos: el registro de sentencias debe protegerse y revisarse antes de exportarse.
