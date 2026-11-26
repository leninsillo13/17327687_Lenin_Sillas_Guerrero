-- LAB-03 Actividad 1 — Calidad de datos desde la operación
-- Inserta (una sola vez) los dos registros con errores y ejecuta las verificaciones.

INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal)
SELECT 'Ana Lopez', 'ANA.LOPEZ@example.test', '6671234567', 'LOAA850315AB', 41, 'Culiacan', '80000'
WHERE NOT EXISTS (SELECT 1 FROM clientes WHERE correo = 'ANA.LOPEZ@example.test');

INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal)
SELECT 'Jorge Díaz', 'sin-correo', '667', NULL, -3, 'Culiacán', '8000'
WHERE NOT EXISTS (SELECT 1 FROM clientes WHERE correo = 'sin-correo');

\echo '--- C1: posibles duplicados por correo'
SELECT lower(correo) AS correo_normalizado, count(*) AS registros, string_agg(id::text, ', ') AS ids
FROM clientes GROUP BY lower(correo) HAVING count(*) > 1;

\echo '--- C2: RFC con formato no valido o ausente'
SELECT id, nombre, rfc FROM clientes
WHERE rfc IS NULL OR rfc !~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$';

\echo '--- C3: correo con formato no valido'
SELECT id, nombre, correo FROM clientes
WHERE correo !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$';

\echo '--- C4: edad fuera de rango'
SELECT id, nombre, edad FROM clientes
WHERE edad IS NOT NULL AND (edad < 18 OR edad > 120);

\echo '--- C5: telefono que no tiene 10 digitos'
SELECT id, nombre, telefono FROM clientes
WHERE telefono IS NOT NULL AND telefono !~ '^[0-9]{10}$';

\echo '--- C6: codigo postal que no tiene 5 digitos'
SELECT id, nombre, codigo_postal FROM clientes
WHERE codigo_postal IS NOT NULL AND codigo_postal !~ '^[0-9]{5}$';

\echo '--- C7: ciudad escrita con variantes (acentos)'
SELECT translate(lower(ciudad), 'áéíóú', 'aeiou') AS ciudad_normalizada,
       count(DISTINCT ciudad) AS variantes, string_agg(DISTINCT ciudad, ' | ') AS escrituras
FROM clientes GROUP BY 1 HAVING count(DISTINCT ciudad) > 1;

\echo '--- Completitud'
SELECT count(*) AS total,
       count(*) FILTER (WHERE telefono IS NULL) AS sin_telefono,
       count(*) FILTER (WHERE rfc IS NULL) AS sin_rfc
FROM clientes;
