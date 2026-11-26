-- LAB-03 Actividad 4 — Catálogo mínimo de datos (parte técnica)
ANALYZE;

\echo '--- Tablas'
SELECT n.nspname                                     AS esquema,
       c.relname                                     AS tabla,
       pg_get_userbyid(c.relowner)                   AS propietario_tecnico,
       c.reltuples::bigint                           AS filas_estimadas,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS tamano,
       obj_description(c.oid, 'pg_class')            AS descripcion
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;

\echo '--- Vistas (activos que la consulta anterior no lista, p. ej. dba.bitacora)'
SELECT n.nspname                       AS esquema,
       c.relname                       AS vista,
       pg_get_userbyid(c.relowner)     AS propietario_tecnico,
       obj_description(c.oid, 'pg_class') AS descripcion
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('v', 'm')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY 1, 2;

\echo '--- Esquemas'
SELECT nspname AS esquema, pg_get_userbyid(nspowner) AS propietario_tecnico
FROM pg_namespace
WHERE nspname NOT LIKE 'pg\_%' AND nspname <> 'information_schema'
ORDER BY 1;
