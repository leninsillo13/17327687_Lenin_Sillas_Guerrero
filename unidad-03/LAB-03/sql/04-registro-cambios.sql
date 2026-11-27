-- LAB-03 Actividad 7 — Registro de cambios y conciliación
-- Es seguro ejecutarlo más de una vez: no duplica el esquema, la tabla, el folio ni la columna.

CREATE SCHEMA IF NOT EXISTS gobierno;
REVOKE ALL ON SCHEMA gobierno FROM PUBLIC;

CREATE TABLE IF NOT EXISTS gobierno.solicitudes_cambio (
    folio            TEXT PRIMARY KEY,
    descripcion      TEXT NOT NULL,
    solicitado_por   TEXT NOT NULL,
    aprobado_por     TEXT,
    ambiente         TEXT NOT NULL CHECK (ambiente IN ('desarrollo', 'pruebas', 'produccion')),
    fecha_aprobacion TIMESTAMPTZ,
    ventana_inicio   TIMESTAMPTZ,
    ventana_fin      TIMESTAMPTZ
);

COMMENT ON TABLE gobierno.solicitudes_cambio IS 'Registro de solicitudes de cambio en la base comercial. Propietario: Comité de cambios. Custodio: DBA. Evidencia de POL-06.';

-- Solicitud aprobada, con ventana de 1 hora que ya está abierta
INSERT INTO gobierno.solicitudes_cambio VALUES
('CAM-2026-014', 'Agregar columna canal_alta a clientes', 'Gerencia Comercial',
 'Comité de cambios', 'produccion', now() - interval '1 day',
 now() - interval '5 minutes', now() + interval '1 hour')
ON CONFLICT (folio) DO NOTHING;

-- El cambio, dentro de la ventana (solo si la columna aún no existe)
SELECT count(*) = 0 AS falta
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'clientes' AND column_name = 'canal_alta' \gset
\if :falta
ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20);
\endif
COMMENT ON COLUMN clientes.canal_alta IS 'Canal por el que se registró el cliente. Cambio CAM-2026-014.';

\echo '--- Verificación de la ventana'
SELECT folio, aprobado_por,
       ventana_inicio <= now() AND now() <= ventana_fin AS dentro_de_ventana
FROM gobierno.solicitudes_cambio;

-- Espera a que el colector escriba las últimas líneas en el archivo de bitácora
SELECT pg_sleep(3);

\echo '--- Cambios de estructura y privilegios en la bitácora (base de la conciliación)'
SELECT num,
       substr(linea, 1, 23)                    AS momento,
       substring(linea from 'user=([^ ]*)')     AS usuario,
       substring(linea from '(?:statement|sentencia|instrucci.n): (.*)$') AS sentencia
FROM dba.bitacora
WHERE linea ~ '(statement|sentencia|instrucci.n): (CREATE|ALTER|DROP|GRANT|REVOKE)'
ORDER BY num;

-- ==============================================================================
-- Bitácora histórica (consultas H0 a H10): lee todos los archivos de pg_ls_logdir()
-- ==============================================================================
-- Las contraseñas se enmascaran al cargar las líneas.

CREATE TEMP TABLE bitacora_total AS
SELECT f.name AS archivo,
       t.n::int AS num,
       replace(
         regexp_replace(t.linea, 'PASSWORD +''[^'']*''', 'PASSWORD ''<REDACTED>''', 'gi'),
         'Temporal_Practica_2026', '<REDACTED>') AS linea
FROM (SELECT name, convert_from(pg_read_binary_file('log/' || name), 'LATIN1') AS txt
      FROM pg_ls_logdir()
      WHERE name LIKE '%.log' AND size > 0) f
CROSS JOIN LATERAL regexp_split_to_table(f.txt, E'\r?\n') WITH ORDINALITY AS t(linea, n);

\echo '--- H0: líneas y rango de fechas por archivo'
SELECT archivo,
       count(*) AS lineas,
       min(substr(linea, 1, 23)) FILTER (WHERE linea ~ '^[0-9]{4}-') AS primera,
       max(substr(linea, 1, 23)) FILTER (WHERE linea ~ '^[0-9]{4}-') AS ultima
FROM bitacora_total
GROUP BY archivo
ORDER BY archivo;

\echo '--- H1: CREATE / ALTER / DROP / GRANT / REVOKE en todos los archivos (base de la conciliación)'
SELECT archivo, num,
       substr(linea, 1, 23)                    AS momento,
       substring(linea from 'user=([^ ]*)')    AS usuario,
       left(substring(linea from '(?:statement|sentencia|instrucci.n): (.*)$'), 150) AS sentencia
FROM bitacora_total
WHERE linea ~ '(statement|sentencia|instrucci.n): (CREATE|ALTER|DROP|GRANT|REVOKE)'
  AND linea !~ 'bitacora_total'
ORDER BY archivo, num;

\echo '--- H2: ENABLE / DISABLE TRIGGER'
SELECT archivo, num,
       substr(linea, 1, 23)                    AS momento,
       substring(linea from 'user=([^ ]*)')    AS usuario,
       substring(linea from 'app=([^ ]*)')     AS app,
       left(substring(linea from '(?:statement|sentencia|instrucci.n): (.*)$'), 100) AS sentencia
FROM bitacora_total
WHERE linea ~* '(statement|sentencia|instrucci.n): ALTER TABLE .* (ENABLE|DISABLE) TRIGGER'
ORDER BY archivo, num;

\echo '--- H3: UPDATE sobre clientes (RFC enmascarado)'
SELECT archivo, num,
       substr(linea, 1, 23)                    AS momento,
       substring(linea from 'user=([^ ]*)')    AS usuario,
       substring(linea from 'app=([^ ]*)')     AS app,
       left(regexp_replace(substring(linea from '(?:statement|sentencia|instrucci.n): (.*)$'),
                           'rfc *= *''[^'']*''', 'rfc=''<RFC>''', 'gi'), 150) AS sentencia
FROM bitacora_total
WHERE linea ~* '(statement|sentencia|instrucci.n): UPDATE clientes'
ORDER BY archivo, num
LIMIT 40;

\echo '--- H4: sentencias con PASSWORD (secretos que llegaron a la bitácora; ya enmascarados aquí)'
SELECT archivo, num,
       substr(linea, 1, 23)                    AS momento,
       substring(linea from 'user=([^ ]*)')    AS usuario,
       left(substring(linea from '(?:statement|sentencia|instrucci.n): (.*)$'), 90) AS sentencia
FROM bitacora_total
WHERE linea ~* '(statement|sentencia|instrucci.n): .*password'
  AND linea !~ 'bitacora_total'
ORDER BY archivo, num;

\echo '--- H5: conexiones autorizadas por usuario / aplicación / cliente'
SELECT substring(linea from 'user=([^ ]*)')    AS usuario,
       substring(linea from 'app=([^ ]*)')     AS app,
       substring(linea from 'client=([^ ]*)')  AS cliente,
       count(*)                                AS conexiones,
       min(substr(linea, 1, 19))               AS primera,
       max(substr(linea, 1, 19))               AS ultima
FROM bitacora_total
WHERE linea ~* '(conexi.n autorizada|connection authorized)'
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

\echo '--- H6: errores FATAL (por ejemplo, autenticación fallida)'
SELECT archivo, num, left(linea, 190) AS linea
FROM bitacora_total
WHERE linea ~ 'FATAL'
ORDER BY archivo, num
LIMIT 30;

\echo '--- H7: inicios, apagados e interrupciones del servidor'
SELECT archivo, num, left(linea, 170) AS linea
FROM bitacora_total
WHERE linea ~* '(interrumpido|no fue apagado|se est. apagando|shutting down|apagado|shutdown|listo para aceptar|ready to accept)'
ORDER BY archivo, num
LIMIT 60;

\echo '--- H8: cambios del parámetro log_statement (cuándo estuvo en none o en mod)'
SELECT archivo, num, left(linea, 190) AS linea
FROM bitacora_total
WHERE linea ~* 'log_statement'
ORDER BY archivo, num
LIMIT 20;

\echo '--- H9: COMMENT ON registrados (¿los COMMENT quedan en la bitácora?)'
SELECT archivo, num,
       substr(linea, 1, 23)                    AS momento,
       substring(linea from 'user=([^ ]*)')    AS usuario,
       left(substring(linea from '(?:statement|sentencia|instrucci.n): (.*)$'), 80) AS sentencia
FROM bitacora_total
WHERE linea ~ '(statement|sentencia|instrucci.n): COMMENT ON'
ORDER BY archivo, num DESC
LIMIT 12;

\echo '--- H10: línea completa del ALTER de canal_alta (muestra el prefijo real del registro)'
SELECT archivo, num, left(linea, 220) AS linea
FROM bitacora_total
WHERE linea ~ 'ADD COLUMN canal_alta'
  AND linea !~ 'bitacora_total'
ORDER BY archivo, num;
