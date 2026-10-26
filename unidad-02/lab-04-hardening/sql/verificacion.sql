-- LAB-04 | 04-verificacion.sql
-- Verificación final del hardening.
-- Ejecutar como postgres en una conexión NUEVA (para que pg_stat_ssl refleje TLS).
-- Una consulta a la vez en pgAdmin. La consulta 1 es la captura 06-verificacion.png.

-- 1. Parámetros clave (captura 06-verificacion.png)
SELECT name, setting
FROM pg_settings
WHERE name IN ('listen_addresses', 'port', 'ssl', 'ssl_min_protocol_version',
               'password_encryption', 'idle_in_transaction_session_timeout',
               'statement_timeout', 'max_connections',
               'log_connections', 'log_disconnections')
ORDER BY name;

-- 2. Reglas de pg_hba.conf (la columna error debe estar vacía)
SELECT line_number, type, database, user_name, address, auth_method, error
FROM pg_hba_file_rules
ORDER BY line_number;

-- 3. Roles y privilegios
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin
FROM pg_roles
WHERE rolname NOT LIKE 'pg\_%'
ORDER BY rolname;

-- 4. Membresías de roles de grupo
SELECT r.rolname AS rol_grupo, m.rolname AS miembro
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE r.rolname IN ('analista', 'soporte');

-- 5. Timeout específico de la cuenta de aplicación
SELECT rolname, rolconfig FROM pg_roles WHERE rolname = 'app_lab';

-- 6. Extensiones (debe quedar solo plpgsql)
SELECT extname, extversion FROM pg_extension ORDER BY extname;

-- 7. TLS de la conexión actual (debe mostrar ssl = true, TLSv1.3)
SELECT s.pid, a.usename, a.client_addr, s.ssl, s.version, s.cipher
FROM pg_stat_ssl s
JOIN pg_stat_activity a USING (pid)
WHERE s.pid = pg_backend_pid();

-- 8. Conexiones actuales (todas deben venir de localhost)
SELECT pid, usename, datname, client_addr, application_name
FROM pg_stat_activity
WHERE client_addr IS NOT NULL;

-- Verificaciones en PowerShell (no SQL):
--   netstat -ano | findstr 5432
--       esperado: solo 127.0.0.1:5432 y [::1]:5432 en LISTENING
--   icacls "C:\Program Files\PostgreSQL\18\data"
--       esperado: sin Users ni Everyone
