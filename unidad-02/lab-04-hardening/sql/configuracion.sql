-- LAB-04 | 03-configuracion.sql
-- Cambios de configuración aplicados (Cambios 3 a 7)
-- Ejecutar como postgres. Una sentencia a la vez en pgAdmin.
-- Nota: los cambios de pg_hba.conf (Cambio 2) y listen_addresses (Cambio 3)
-- se hacen editando los archivos; aquí solo se documentan y se verifican.

------------------------------------------------------------
-- CAMBIO 2: pg_hba.conf (edición manual del archivo)
-- Ruta: C:/Program Files/PostgreSQL/18/data/pg_hba.conf
------------------------------------------------------------
-- Reglas finales aplicadas:
--
-- local   all             postgres                                scram-sha-256
-- host    postgres        postgres        127.0.0.1/32            scram-sha-256
-- host    postgres        postgres        ::1/128                 scram-sha-256
-- host    laboratorios    postgres        127.0.0.1/32            scram-sha-256
-- host    laboratorios    postgres        ::1/128                 scram-sha-256
-- host    postgres,laboratorios   dba_lab   127.0.0.1/32          scram-sha-256
-- host    postgres,laboratorios   dba_lab   ::1/128               scram-sha-256
-- host    laboratorios    app_lab         127.0.0.1/32            scram-sha-256
-- host    laboratorios    app_lab         ::1/128                 scram-sha-256
-- host    laboratorios    consulta_lab    127.0.0.1/32            scram-sha-256
-- host    laboratorios    consulta_lab    ::1/128                 scram-sha-256
--
-- (reglas de replication eliminadas: no se usa replicación)

SELECT pg_reload_conf();

SELECT line_number, type, database, user_name, address, auth_method, error
FROM pg_hba_file_rules
ORDER BY line_number;

------------------------------------------------------------
-- CAMBIO 3: listen_addresses (edición de postgresql.conf + reinicio)
------------------------------------------------------------
-- En postgresql.conf:  listen_addresses = 'localhost'
-- Reinicio (PowerShell como Administrador):
--   Restart-Service postgresql-x64-18

SHOW listen_addresses;

------------------------------------------------------------
-- CAMBIO 4: timeouts de sesión
------------------------------------------------------------
ALTER SYSTEM SET idle_in_transaction_session_timeout = '5min';

SELECT pg_reload_conf();

ALTER ROLE app_lab SET statement_timeout = '30s';

SHOW idle_in_transaction_session_timeout;

SELECT rolname, rolconfig FROM pg_roles WHERE rolname = 'app_lab';

------------------------------------------------------------
-- CAMBIO 5: TLS
-- Antes, en PowerShell, se generó el certificado autofirmado:
--   cd "C:\Program Files\PostgreSQL\18\data"
--   & "C:\Program Files\Git\usr\bin\openssl.exe" req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=localhost"
------------------------------------------------------------
ALTER SYSTEM SET ssl = on;

SELECT pg_reload_conf();

SHOW ssl;

-- Verificar desde una conexión nueva:
SELECT s.pid, a.usename, a.client_addr, s.ssl, s.version, s.cipher
FROM pg_stat_ssl s
JOIN pg_stat_activity a USING (pid)
WHERE s.pid = pg_backend_pid();

------------------------------------------------------------
-- CAMBIO 6: eliminación de pgcrypto
------------------------------------------------------------
-- Comprobaciones previas (en la base "laboratorios"):

SELECT schemaname, viewname
FROM pg_views
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND definition ~* '(crypt|gen_salt|digest|hmac|pgp_|armor|decrypt|encrypt)';

SELECT n.nspname, p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND p.prosrc ~* '(crypt|gen_salt|digest|hmac|pgp_|armor)'
  AND NOT EXISTS (SELECT 1 FROM pg_depend d
                  WHERE d.objid = p.oid AND d.deptype = 'e');

-- Prueba segura (se deshace):
BEGIN;
DROP EXTENSION pgcrypto;
ROLLBACK;

-- Aplicación (sin CASCADE):
DROP EXTENSION pgcrypto;

SELECT extname, extversion FROM pg_extension ORDER BY extname;

------------------------------------------------------------
-- CAMBIO 7: registro de conexiones
------------------------------------------------------------
ALTER SYSTEM SET log_connections = 'receipt,authentication,authorization';

ALTER SYSTEM SET log_disconnections = on;

SELECT pg_reload_conf();

SHOW log_connections;

SHOW log_disconnections;

------------------------------------------------------------
-- REVERSIÓN (referencia)
------------------------------------------------------------
-- ALTER SYSTEM RESET idle_in_transaction_session_timeout;
-- ALTER ROLE app_lab RESET statement_timeout;
-- ALTER SYSTEM RESET ssl;
-- CREATE EXTENSION pgcrypto;
-- ALTER SYSTEM RESET log_connections;
-- ALTER SYSTEM RESET log_disconnections;
-- SELECT pg_reload_conf();
