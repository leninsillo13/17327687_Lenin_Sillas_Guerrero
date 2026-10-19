SELECT *
FROM clientes
WHERE fecha_alta <
      CURRENT_DATE - INTERVAL '5 years';

SET ROLE soporte;

SELECT *
FROM v_clientes_soporte;

SELECT *
FROM clientes;

SET ROLE analista;

SELECT *
FROM analitica.clientes;

SELECT *
FROM pii.mapa_cliente;

SELECT *
FROM public.clientes;