# Actividad 8 — Analizar un escenario de seguridad

## Objetivo

Analizar un escenario donde los usuarios y roles están bien configurados, pero existen fallas de protección de datos en reposo, en tránsito y de gestión de claves. El propósito es identificar los riesgos, proponer el mecanismo adecuado para cada elemento y evaluar qué problema es el más crítico.

## Comando o procedimiento

Análisis conceptual del escenario con base en lo practicado en las actividades anteriores (hash con sal, cifrado simétrico, TLS, `sslmode` y gestión de claves). No requiere ejecutar comandos.

**Escenario:** una empresa almacena nombre, correo electrónico, contraseña, RFC, información financiera y claves criptográficas. Los usuarios y roles están bien configurados, pero:

- Las contraseñas están en texto claro.
- El RFC está en texto claro.
- Las conexiones no validan adecuadamente al servidor.
- Las claves criptográficas aparecen en archivos SQL.
- Los respaldos se almacenan sin protección adicional.

## Resultado obtenido

### Pregunta 1. ¿Cuáles son los principales riesgos?

| Problema | Riesgo principal |
|---|---|
| Contraseñas en texto claro | Quien obtenga la base, un respaldo o un volcado ve todas las credenciales. Puede suplantar usuarios y probarlas en otros servicios donde se reutilizan. |
| RFC en texto claro | Exposición de un dato personal sensible ante una filtración, con riesgo de suplantación de identidad y fraude, además de posibles consecuencias legales por no proteger datos personales. |
| Conexiones sin validación adecuada del servidor (por ejemplo, `sslmode=require` o `prefer` en lugar de `verify-full`) | El tráfico puede ir cifrado, pero el cliente no comprueba con quién habla. Un atacante que suplante al servidor (*man-in-the-middle*) puede leer o alterar consultas, resultados y credenciales. |
| Claves criptográficas en archivos SQL | Las claves quedan expuestas en repositorios, historial de Git, logs, respaldos y capturas. Quien las obtiene puede descifrar todos los datos protegidos con ellas. |
| Respaldos sin protección adicional | Contienen toda la información y están fuera del control de roles y permisos de la base. Si se pierden o se roban, se leen sin restricción. |
| Información financiera (sin protección indicada) | Si no se cifra ni se controla su acceso, comparte los mismos riesgos de filtración y de lectura desde respaldos. |

### Pregunta 2. ¿Qué mecanismo utilizarías para cada elemento?

| Elemento | Mecanismo | Justificación |
|---|---|---|
| Nombre | Control de acceso por roles y permisos (cifrado solo si la política lo exige) | Es un dato de menor sensibilidad. |
| Correo electrónico | Control de acceso por roles y permisos (cifrado si se considera sensible) | Es un dato personal que se consulta con frecuencia. |
| Contraseña | Hash con sal con algoritmo para contraseñas (bcrypt con `crypt()` y `gen_salt('bf')`; en aplicaciones reales, Argon2id, scrypt o bcrypt según el framework) | Nunca debe recuperarse, solo verificarse. |
| RFC | Cifrado simétrico reversible (`pgp_sym_encrypt()` / `pgp_sym_decrypt()`) con clave gestionada fuera de la base | La aplicación necesita poder leerlo, por lo que se requiere cifrado reversible. |
| Información financiera | Cifrado en reposo del dato sensible, acceso mínimo por roles y registro de accesos | Es información de alto impacto que debe protegerse aunque se filtre la base. |
| Conexiones cliente-servidor | TLS habilitado (`ssl = on`, versión mínima `TLSv1.2` o superior) y `sslmode=verify-full` en los clientes | Protege el tráfico y valida la identidad del servidor. |
| Claves criptográficas | Gestor de secretos o KMS, con acceso restringido, rotación y separación de los datos y del código; nunca en archivos SQL ni en el repositorio | La seguridad del cifrado depende de la protección de la clave. |
| Respaldos | Cifrado del archivo de respaldo y del medio de almacenamiento, con clave separada, acceso restringido y copias controladas | Protege los datos en reposo fuera de la base. |

### Pregunta 3. ¿Cuál de los problemas consideras más crítico y por qué?

El más crítico es **el almacenamiento de las claves criptográficas en archivos SQL**.

- La clave es el elemento del que depende todo el cifrado. Si se expone, el cifrado del RFC, de la información financiera y de los respaldos cifrados deja de proteger, sin importar qué tan bien esté implementado.
- Los archivos SQL se copian a repositorios, historiales, respaldos y capturas. Una vez publicada, la clave queda expuesta de forma permanente y no basta con borrar el archivo (Actividad 3).
- Es un fallo que anula las demás protecciones, mientras que los otros problemas afectan a un dato o a un canal específico.
- Su corrección requiere rotar la clave y volver a cifrar los datos, lo que lo hace costoso de remediar.

Las contraseñas en texto claro también son gravísimas porque no existe ninguna barrera entre el atacante y las credenciales, pero su impacto se limita a ese dato. La pérdida de una clave compromete todo lo que protege.

### Pregunta 4. ¿Tener correctamente configurados los usuarios y permisos elimina estos riesgos?

**No.** Los usuarios, roles y permisos controlan quién puede acceder a los datos a través de la base de datos, pero no protegen los datos en sí cuando se accede por otras vías:

- **Respaldos y archivos del disco:** se pueden leer sin pasar por los roles de PostgreSQL. Si están sin cifrar, los permisos de la base no los protegen.
- **Filtraciones y copias:** si la base se copia o se filtra, los datos en texto claro (contraseñas, RFC) quedan legibles.
- **Tráfico de red:** los permisos no impiden que alguien intercepte o suplante el canal si no hay TLS con validación del servidor.
- **Claves expuestas:** un archivo SQL o un repositorio con claves no está sujeto a los permisos de la base de datos.
- **Usuarios con acceso legítimo:** administradores o roles con privilegios amplios podrían ver datos sensibles en texto claro, mientras que el cifrado reduce lo que pueden leer.
- **Credenciales comprometidas:** si una cuenta con permisos se vulnera, el atacante hereda esos permisos; el cifrado y el hash limitan el daño.

Los permisos son una capa necesaria, pero no suficiente. La seguridad requiere defensa en profundidad: control de acceso, cifrado en reposo, protección en tránsito y gestión de claves.

## Análisis

El escenario muestra que una buena administración de usuarios y roles no compensa las fallas en la protección de los datos. Cada problema corresponde a una categoría distinta:

- **En reposo:** contraseñas y RFC en texto claro, y respaldos sin protección.
- **En tránsito:** conexiones sin validación adecuada del servidor.
- **Gestión de claves:** claves en archivos SQL.

Estas categorías se complementan: cifrar el RFC no sirve si la clave está en un script, y usar TLS no sirve si el cliente no verifica al servidor. La seguridad es tan fuerte como su eslabón más débil.

## Conclusión

Aunque los usuarios y roles estén bien configurados, la empresa sigue expuesta a filtraciones, suplantación y pérdida de confidencialidad. Se debe aplicar hash con sal a las contraseñas, cifrado reversible al RFC y a la información financiera, TLS con `verify-full` en las conexiones, un gestor de secretos para las claves y cifrado de los respaldos. El problema más crítico es la exposición de las claves criptográficas, porque invalida el resto de las protecciones. Los permisos son una capa necesaria, pero no sustituyen al cifrado, a la protección del canal ni a la gestión segura de claves.