# Actividad 10 — Crear una política mínima de protección de claves

## Objetivo

Definir una política mínima de gestión de claves criptográficas que cubra todo su ciclo de vida: generación, almacenamiento, acceso, rotación, respaldo, revocación, exposición accidental y eliminación.

## Comando o procedimiento

Elaboración de una política de 8 reglas, una por cada aspecto exigido, a partir de lo analizado en las actividades anteriores (cifrado simétrico, exposición de claves en scripts, TLS y escenario de seguridad). No requiere ejecutar comandos.

## Resultado obtenido

### Política de protección de claves criptográficas

**Regla 1. Generación**
Toda clave debe generarse con un generador de números aleatorios criptográficamente seguro y con una longitud acorde a las recomendaciones vigentes. Está prohibido derivar claves de palabras, fechas, nombres o valores predecibles, y reutilizar la misma clave para propósitos distintos (por ejemplo, cifrar datos y firmar).

**Regla 2. Almacenamiento**
Las claves deben almacenarse únicamente en un gestor de secretos o servicio de gestión de claves (KMS), separadas de los datos que protegen. Nunca deben guardarse en la misma base, tabla, respaldo ni servidor que los datos cifrados con ellas.

**Regla 3. Acceso**
El acceso a una clave se concede bajo el principio de mínimo privilegio: solo a las aplicaciones o personas que lo necesiten, con identidad individual, y con registro de cada uso o consulta. Las claves no se comparten por correo, mensajería ni documentos, y no se escriben en consultas, scripts, archivos de configuración ni código.

**Regla 4. Rotación**
Cada clave tiene una vigencia definida y se rota periódicamente, y también cuando cambia el personal con acceso o se sospecha un compromiso. Durante la rotación, los datos se vuelven a cifrar con la clave nueva y se conserva la anterior solo el tiempo necesario para completarla.

**Regla 5. Respaldo**
Las copias de las claves deben estar cifradas, almacenadas en un lugar distinto al de la clave original y protegidas con un control de acceso al menos igual de estricto. Debe existir un procedimiento probado de recuperación, porque perder la clave equivale a perder los datos cifrados.

**Regla 6. Revocación**
Cuando una clave deja de ser confiable (compromiso, salida de una persona o fin de su uso), debe revocarse de inmediato, impidiendo nuevos usos, y sustituirse por una clave nueva. Se debe documentar quién la revocó, cuándo y por qué.

**Regla 7. Exposición accidental**
Si una clave aparece en un repositorio, log, captura, correo o documento, se considera comprometida, aunque el archivo se borre después. Se debe revocar y rotar de inmediato, revisar los accesos realizados con ella, eliminar la exposición y reportar el incidente. Para prevenirlo, se deben usar herramientas de detección de secretos y excluir de los repositorios los archivos sensibles (por ejemplo, con `.gitignore`).

**Regla 8. Eliminación**
Al terminar su ciclo de vida, la clave se destruye de forma segura en todos sus lugares (gestor de secretos, respaldos y copias), solo después de verificar que ya no existen datos que dependan de ella o que fueron vueltos a cifrar. La destrucción queda registrada.

## Análisis

**Relación con lo practicado en el laboratorio**
- La Actividad 3 mostró que escribir `'CLAVE-DE-PRUEBA'` en una consulta expone la clave en scripts, repositorios, logs y respaldos. Las reglas 2, 3 y 7 atienden ese problema.
- En la Actividad 8, las claves en archivos SQL se identificaron como el problema más crítico porque su exposición anula el cifrado del resto de los datos. Las reglas 6 y 7 establecen cómo reaccionar cuando ocurre.
- La Actividad 2 mostró que el cifrado con `pgp_sym_encrypt()` solo es tan fuerte como su clave. La regla 4 limita el daño en el tiempo y la regla 5 evita perder datos por perder la clave.

**Por qué las reglas se complementan**
Almacenar bien la clave (regla 2) no basta si cualquiera puede acceder a ella (regla 3). Rotarla (regla 4) pierde valor si se conserva una copia sin protección (regla 5). Y la revocación (regla 6) es necesaria cuando falla alguna de las anteriores.

## Conclusión

La seguridad de los datos cifrados depende de cómo se gestionan las claves durante todo su ciclo de vida, no solo del algoritmo. La política de ocho reglas cubre desde la generación hasta la eliminación, separa las claves de los datos y del código, limita quién puede usarlas y define cómo actuar ante una exposición. Aplicarla evita los problemas vistos en el laboratorio: claves en scripts, claves junto a los datos y falta de respuesta ante un compromiso.

# Verificación final

## Credenciales

**¿Una contraseña debe cifrarse o protegerse mediante un mecanismo de derivación de claves para contraseñas?**

Debe protegerse mediante un mecanismo de derivación de claves para contraseñas (hash con sal y costo ajustable, como Argon2id, scrypt o bcrypt), no cifrarse. El cifrado es reversible y depende de una clave: si esa clave se expone, todas las contraseñas pueden recuperarse. En cambio, estos mecanismos son de una sola vía, usan una sal aleatoria por contraseña y son deliberadamente lentos para dificultar los ataques de fuerza bruta. Como solo se necesita verificar la contraseña y no recuperarla, el hash es la opción adecuada (en el laboratorio se usó `crypt()` con `gen_salt('bf')`).

## Datos sensibles

**¿Qué diferencia existe entre enmascaramiento, seudonimización y cifrado?**

- **Enmascaramiento:** oculta u oscurece parte del dato para mostrarlo o usarlo sin revelarlo completo (por ejemplo, `LOPA******ABC`). Se usa en pantallas, reportes o entornos de prueba. Suele ser irreversible o no está pensado para recuperar el dato original.
- **Seudonimización:** sustituye los identificadores directos por un seudónimo o identificador (por ejemplo, un ID), guardando la tabla de correspondencia por separado. Permite volver a identificar a la persona solo con esa información adicional. Reduce el riesgo, pero los datos siguen siendo personales.
- **Cifrado:** transforma el dato con un algoritmo y una clave, de modo que solo quien tenga la clave puede recuperarlo. Protege la confidencialidad del dato en reposo o en tránsito y es reversible (por ejemplo, `pgp_sym_encrypt()` / `pgp_sym_decrypt()`).

## Comunicaciones

**¿Qué problema resuelve TLS?**

Protege la información que viaja entre cliente y servidor: garantiza la confidencialidad (nadie en la red puede leer el tráfico), la integridad (detecta si los datos fueron alterados) y, con certificados validados (`verify-full`), la autenticidad del servidor, evitando que alguien se haga pasar por él (*man-in-the-middle*). Resuelve el problema de enviar datos sensibles, como consultas, resultados y credenciales, en texto claro por la red.

## Claves

**¿Dónde debería almacenarse una clave criptográfica en un entorno real?**

En un gestor de secretos o un servicio de gestión de claves (KMS o HSM), separado de los datos que protege y del código. Debe tener acceso restringido por mínimo privilegio, registro de uso y rotación periódica. No debe almacenarse en scripts, consultas, archivos de configuración dentro del repositorio, ni en el mismo lugar que los datos cifrados.

## Repositorio

**¿Es correcto subir una contraseña o clave real a GitLab aunque el repositorio sea privado?**

No.

Un repositorio privado reduce la exposición, pero no convierte un secreto en información apropiada para almacenar dentro del código. Cualquier persona con acceso al repositorio, sus clones, forks, respaldos o historial de commits podría leer el secreto, y los accesos pueden cambiar o comprometerse con el tiempo. Además, aunque el archivo se borre después, el secreto permanece en el historial. Los secretos deben guardarse en un gestor de secretos o en variables protegidas, fuera del código.