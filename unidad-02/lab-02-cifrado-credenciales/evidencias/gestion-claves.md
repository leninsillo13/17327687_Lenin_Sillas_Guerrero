# Actividad 3 — El problema de la gestión de claves

## Objetivo

Identificar por qué colocar una clave de cifrado directamente en el código es una mala práctica, analizar los riesgos de exponerla (por ejemplo, en un repositorio Git) y aplicar la regla del laboratorio de no almacenar secretos reales en el repositorio.

## Comando o procedimiento

**1. Crear el archivo temporal de demostración** (`sql/ejemplo-mala-practica.sql`) con una clave ficticia:

```sql
SELECT pgp_sym_decrypt(
    rfc_cifrado,
    'CLAVE-DE-PRUEBA'
)
FROM clientes_protegidos;
```

**2. Verificar que el archivo existe y revisar su contenido**

```bash
mkdir -p sql
cat sql/ejemplo-mala-practica.sql
```

**3. Eliminar el archivo de demostración antes de la entrega final**

```bash
rm sql/ejemplo-mala-practica.sql
git status
```

## Resultado obtenido

**Contenido del archivo `sql/ejemplo-mala-practica.sql`:**

En el archivo se puede ver que la clave está escrita directamente dentro de la consulta. Aunque en esta práctica es una clave ficticia, se puede observar el riesgo que existiría si se usara una clave real.

## Análisis

**¿Qué ocurriría si esta clave fuera una clave utilizada realmente por una organización y el archivo se publicara en un repositorio Git?**

- **Exposición inmediata:** cualquier persona con acceso al repositorio podría leer la clave. Si el repositorio es público, la podría ver cualquiera en internet.
- **Descifrado de los datos:** si además obtiene la base de datos o un respaldo, puede ejecutar `pgp_sym_decrypt()` con esa clave y recuperar todos los datos sensibles (como los RFC), por lo que el cifrado deja de proteger.
- **Permanencia en el historial:** aunque el archivo se borre después, la clave sigue en el historial de commits, ramas, forks y clones. Eliminarla del último commit no basta.
- **Detección automatizada:** existen bots y herramientas que escanean repositorios en busca de secretos y los explotan en minutos.
- **Alcance amplio:** una misma clave suele cifrar muchos registros, así que el compromiso afecta a todos los datos protegidos con ella.
- **Respuesta necesaria:** la clave debe considerarse comprometida, rotarla, volver a cifrar los datos con una clave nueva, revisar accesos y notificar según corresponda.

**Otras vías de exposición de una clave escrita en el código:** scripts, archivos de configuración, registros de ejecución, capturas de pantalla, respaldos, documentación y variables mal administradas.

**Cómo debe manejarse una clave en una aplicación real:**
- Mantenerla fuera del código y del repositorio.
- Usar un gestor de secretos o KMS, o variables de entorno protegidas.
- Restringir el acceso, rotarla periódicamente y no incluirla en logs.
- Agregar archivos de configuración sensibles a `.gitignore`.

**Aplicación de la regla del laboratorio:**
En esta práctica solo se utilizó un valor ficticio (`CLAVE-DE-PRUEBA`), no se almacenaron claves, contraseñas, tokens ni secretos reales en el repositorio, y el archivo de demostración se eliminó para que no forme parte de la entrega final.

## Conclusión

Escribir una clave directamente en una consulta o script es una mala práctica porque cualquier lugar donde viva ese código (repositorios, respaldos, logs, capturas) se convierte en un punto de fuga. Si el archivo se publica en Git, la clave queda expuesta de forma permanente en el historial y permite descifrar los datos protegidos. La seguridad del cifrado depende de la gestión de la clave, por lo que debe almacenarse separada del código y de los datos, con acceso controlado y rotación. El archivo de demostración se utilizó solo con fines didácticos y se eliminó de la entrega final.