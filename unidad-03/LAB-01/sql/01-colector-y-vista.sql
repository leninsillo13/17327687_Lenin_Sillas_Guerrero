-- LAB-01 · Actividad 2 — Colector de bitácora y vista dba.bitacora
-- Ejecutar en la sesión de administrador (psql -U postgres -d comercial)

-- 1. Activar el colector (requiere REINICIO del servicio).
--    En Windows con EDB suele venir ya activado: revisa primero el valor actual.
SHOW logging_collector;

ALTER SYSTEM SET logging_collector = on;
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';

-- >>> Reiniciar el servicio (PowerShell como administrador):
-- >>>   Restart-Service postgresql-x64-16
-- >>> y volver a abrir la sesión de administrador.

-- 2. Comprobar
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();

-- 3. Leer el archivo vigente desde el propio motor
SELECT linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n') AS linea;

-- 4. Vista de uso exclusivo del administrador
CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';

-- 5. Consultas de ejemplo sobre la vista
-- últimas 10 líneas
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;

-- líneas que contienen un texto, sin distinguir mayúsculas
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';

-- líneas que cumplen una expresión regular
SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';

-- 6. Archivos de bitácora disponibles
SELECT * FROM pg_ls_logdir();
