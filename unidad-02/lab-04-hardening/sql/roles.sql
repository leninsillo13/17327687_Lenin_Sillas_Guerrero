-- LAB-04 | 02-roles.sql
-- Revisión y creación de roles (Actividades 7, 8 y 9, Cambio 1)
-- Ejecutar conectado a la base "laboratorios" como postgres.
-- Ejecutar sentencia por sentencia en pgAdmin (solo muestra el último resultado).

------------------------------------------------------------
-- 1. INSPECCIÓN INICIAL (antes del hardening)
------------------------------------------------------------

SHOW password_encryption;

SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb,
       rolcanlogin, rolreplication, rolbypassrls
FROM pg_roles
WHERE rolname NOT LIKE 'pg\_%'
ORDER BY rolname;

-- Membresías de los roles de grupo (resultado inicial: vacío)
SELECT r.rolname AS rol_grupo, m.rolname AS miembro
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname IN ('analista', 'soporte');

-- Permisos sobre tablas y vistas (ejecutar en "laboratorios")
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('analista', 'soporte')
ORDER BY grantee, table_name;

------------------------------------------------------------
-- 2. CREACIÓN DE CUENTAS SEPARADAS (Cambio 1)
-- IMPORTANTE: reemplaza las contraseñas por unas propias y fuertes.
-- No las guardes en el repositorio.
------------------------------------------------------------

-- Administrador, sin ser superusuario
CREATE ROLE dba_lab LOGIN PASSWORD 'CAMBIAR_CONTRASENA_1'
  NOSUPERUSER CREATEROLE CREATEDB;

-- Aplicación, privilegios mínimos
CREATE ROLE app_lab LOGIN PASSWORD 'CAMBIAR_CONTRASENA_2'
  NOSUPERUSER NOCREATEDB NOCREATEROLE;
GRANT CONNECT ON DATABASE laboratorios TO app_lab;
GRANT soporte TO app_lab;      -- hereda SELECT sobre v_clientes_soporte

-- Consulta, solo lectura
CREATE ROLE consulta_lab LOGIN PASSWORD 'CAMBIAR_CONTRASENA_3'
  NOSUPERUSER NOCREATEDB NOCREATEROLE;
GRANT CONNECT ON DATABASE laboratorios TO consulta_lab;
GRANT analista TO consulta_lab;

------------------------------------------------------------
-- 3. VERIFICACIÓN
------------------------------------------------------------

SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin
FROM pg_roles
WHERE rolname NOT LIKE 'pg\_%'
ORDER BY rolname;

-- Ahora debe devolver 2 filas (app_lab -> soporte, consulta_lab -> analista)
SELECT r.rolname AS rol_grupo, m.rolname AS miembro
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname IN ('analista', 'soporte');

------------------------------------------------------------
-- REVERSIÓN
------------------------------------------------------------
-- REVOKE CONNECT ON DATABASE laboratorios FROM app_lab, consulta_lab;
-- DROP ROLE dba_lab, app_lab, consulta_lab;
