-- LAB-03 Actividad 3 — Diccionario de datos operativo dentro del motor (COMMENT)
-- Documenta la tabla y todas las columnas de clientes. (canal_alta se comenta en 04-registro-cambios.sql)

COMMENT ON TABLE clientes IS 'Clientes de Comercializadora Norte. Propietario: Gerencia Comercial. Custodio: DBA. Clasificación: confidencial (contiene datos personales).';
COMMENT ON COLUMN clientes.id IS 'Identificador interno del cliente. Generado por el sistema.';
COMMENT ON COLUMN clientes.nombre IS 'Nombre completo. Dato personal identificador directo.';
COMMENT ON COLUMN clientes.correo IS 'Correo de contacto. Dato personal. Uso: notificaciones al cliente.';
COMMENT ON COLUMN clientes.telefono IS 'Teléfono de contacto a 10 dígitos. Dato personal. Uso: contacto comercial y soporte.';
COMMENT ON COLUMN clientes.rfc IS 'RFC del cliente. Dato personal. Uso: facturación. Cambios auditados en auditoria.cambios_clientes.';
COMMENT ON COLUMN clientes.edad IS 'Edad en años cumplidos. Dato personal. Uso: analítica agregada.';
COMMENT ON COLUMN clientes.ciudad IS 'Ciudad del cliente. Dato personal (domicilio parcial). Uso: logística y analítica agregada.';
COMMENT ON COLUMN clientes.codigo_postal IS 'Código postal de 5 dígitos. Dato personal (domicilio parcial). Uso: logística y analítica agregada.';
COMMENT ON COLUMN clientes.fecha_alta IS 'Fecha de alta del cliente (tipo date, sin hora). Valor por defecto: fecha actual. No es dato personal sensible.';
COMMENT ON COLUMN clientes.segmento IS 'Segmento comercial asignado al cliente. Agregado en LAB-01. Uso: analítica y campañas.';

\echo '--- Diccionario (estructura + comentarios)'
SELECT c.ordinal_position          AS pos,
       c.column_name               AS columna,
       c.data_type                 AS tipo,
       c.character_maximum_length  AS longitud,
       c.is_nullable               AS acepta_nulos,
       c.column_default            AS valor_por_defecto,
       col_description('public.clientes'::regclass, c.ordinal_position) AS descripcion
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name = 'clientes'
ORDER BY c.ordinal_position;

\echo '--- Columnas SIN comentario (debe devolver 0 filas al final del laboratorio)'
SELECT c.column_name AS columna_sin_comentario
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name = 'clientes'
  AND col_description('public.clientes'::regclass, c.ordinal_position) IS NULL;
