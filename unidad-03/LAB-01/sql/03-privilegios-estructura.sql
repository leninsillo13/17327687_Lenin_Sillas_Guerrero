-- LAB-01 · Actividad 6 — Cambios de privilegios y de estructura
-- Ejecutar en la sesión de administrador, con log_statement = 'ddl' (o superior)

REVOKE UPDATE ON clientes FROM soporte_ana;
GRANT UPDATE ON clientes TO app_ventas;
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);

-- 6.1 Secreto en la sentencia (solo para demostrar el riesgo; contraseña de práctica)
CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';
DROP ROLE rol_temporal;

-- Sentencias registradas
SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;
