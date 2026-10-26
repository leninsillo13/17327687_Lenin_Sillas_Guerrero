# Baseline de seguridad: PostgreSQL 16 en adelante (verificado en 18.6)

Línea base derivada del hardening del LAB-04. Los valores marcados como **aplicado** se verificaron en el laboratorio; los marcados como **recomendado** son mejoras para un entorno de producción.

## 1. Red

| Control | Valor de la baseline | Estado |
|---|---|---|
| Interfaces autorizadas | `listen_addresses = 'localhost'` (o una IP privada específica si hay clientes remotos) | Aplicado |
| Puerto | 5432. Cambiarlo no es un control de seguridad | Aplicado (sin cambio) |
| Firewall | Activo en todos los perfiles; sin regla de entrada para 5432. Si hay clientes remotos, permitir solo su red y denegar el resto | Aplicado |
| Redes permitidas | `127.0.0.1/32` y `::1/128`. Nunca `0.0.0.0/0` ni `::/0` | Aplicado |

## 2. Autenticación

| Control | Valor de la baseline | Estado |
|---|---|---|
| Método | `scram-sha-256` en `password_encryption` y en todas las reglas de `pg_hba.conf`. Evitar `md5` y `trust` | Aplicado |
| Políticas de credenciales | Contraseñas largas y únicas por cuenta, sin almacenarlas en scripts ni repositorios. Rotación periódica | Recomendado |
| Cuentas administrativas | `postgres` solo para emergencias; administración diaria con `dba_lab` (sin `SUPERUSER`) | Aplicado (parcial: migrar pgAdmin a `dba_lab`) |

## 3. Autorización

| Control | Valor de la baseline | Estado |
|---|---|---|
| Roles | Roles de grupo (`analista`, `soporte`) sin `LOGIN`, asignados a cuentas con `LOGIN` | Aplicado |
| Privilegios | Mínimo privilegio. Acceso mediante vistas cuando sea posible. Sin permisos de creación en `public` | Aplicado |
| Cuentas de aplicación | `app_lab` (sin atributos elevados, `statement_timeout = 30s`) y `consulta_lab` (solo lectura). Nunca `SUPERUSER` para una aplicación | Aplicado |
| Revisión pendiente | `analista` tiene `SELECT` directo sobre `analitica.clientes`; confirmar si es necesario | Recomendado |

## 4. Configuración

| Control | Valor de la baseline | Estado |
|---|---|---|
| `pg_hba.conf` | Reglas por base de datos + usuario + origen + método; sin reglas de replicación si no se usa | Aplicado |
| Extensiones | Solo las necesarias. `pgcrypto` eliminada | Aplicado |
| Conexiones | `max_connections = 100`, `superuser_reserved_connections = 3` | Aplicado (sin cambio) |
| Timeouts | `idle_in_transaction_session_timeout = 5min`; `statement_timeout` por rol de aplicación | Aplicado |
| Registro | `log_connections = receipt,authentication,authorization`; `log_disconnections = on` | Aplicado |

## 5. Sistema operativo

| Control | Valor de la baseline | Estado |
|---|---|---|
| Propietario | El servicio corre como `NT AUTHORITY\NetworkService` (cuenta sin privilegios de administrador) | Aplicado |
| Permisos de archivos | Sin acceso para `Users` ni `Everyone` en el directorio de datos, `postgresql.conf`, `pg_hba.conf` y `server.key` | Aplicado |
| Protección del directorio de datos | Acceso solo para `SYSTEM`, `Administradores` y la cuenta del servicio. Quitar el acceso de usuarios personales en producción | Recomendado |
| Archivos `.conf` | Considerar solo lectura para la cuenta del servicio | Recomendado |

## 6. Cifrado

| Control | Valor de la baseline | Estado |
|---|---|---|
| TLS | `ssl = on`, `ssl_min_protocol_version = 'TLSv1.2'`. Verificado: TLSv1.3 con `TLS_AES_256_GCM_SHA384` | Aplicado |
| Certificado | Autofirmado en el laboratorio. En producción, emitido por una CA de confianza y clientes con `sslmode=verify-full` | Recomendado |
| Obligar TLS | Cambiar reglas `host` por `hostssl` para rechazar conexiones sin cifrar | Recomendado |
| Protección de credenciales | Contraseñas almacenadas con SCRAM; `server.key` solo legible por el servicio | Aplicado |
| Información sensible | Exponer datos sensibles solo a través de vistas con las columnas necesarias | Parcial |

## 7. Mantenimiento

| Control | Valor de la baseline | Estado |
|---|---|---|
| Actualización | Aplicar versiones menores de PostgreSQL con regularidad (actualmente 18.6) | Recomendado |
| Revisión periódica | Cada trimestre: `pg_hba_file_rules`, roles y privilegios, extensiones, certificado (vence a los 365 días), logs de conexión, `listen_addresses` | Recomendado |
| Documentación | Registrar todo cambio en `cambios.md` con valor anterior, nuevo, motivo y reversión | Aplicado |