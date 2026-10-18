CREATE ROLE soporte NOLOGIN;

CREATE VIEW v_clientes_soporte AS
SELECT
    id,
    nombre,

    CONCAT(
        LEFT(correo, 2),
        '*****',
        SUBSTRING(correo FROM POSITION('@' IN correo))
    ) AS correo,

    CONCAT(
        '******',
        RIGHT(telefono, 4)
    ) AS telefono,

    CONCAT(
        '*********',
        RIGHT(rfc, 4)
    ) AS rfc

FROM clientes;

SELECT *
FROM v_clientes_soporte;

GRANT USAGE
ON SCHEMA public
TO soporte;

GRANT SELECT
ON v_clientes_soporte
TO soporte;

REVOKE ALL
ON clientes
FROM soporte;

SELECT *
FROM v_clientes_soporte;

SELECT *
FROM clientes;

SELECT current_user;

SET ROLE soporte;

SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_name, grantee;

RESET ROLE;