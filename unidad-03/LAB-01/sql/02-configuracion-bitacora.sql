-- LAB-01 · Actividad 4 — Configurar la bitácora (y niveles de la Actividad 7)
-- Ejecutar en la sesión de administrador

ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();

-- NOTA: la recarga es asíncrona. Ejecuta la verificación en una consulta POSTERIOR,
-- no en el mismo bloque que pg_reload_conf().
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_disconnections', 'log_line_prefix', 'log_statement');

-- Últimas líneas de la bitácora
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;

-- ---------------------------------------------------------------------------
-- Actividad 7 — Subir el nivel a 'mod' (después de comprobar que 'ddl' no registra UPDATE)
-- ---------------------------------------------------------------------------
ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();
