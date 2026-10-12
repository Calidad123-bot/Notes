# Quick Notes para Android

Este proyecto envuelve la app web existente en un `WebView` y está preparado para abrirse con Android Studio. Las notas siguen guardándose en el almacenamiento web local del dispositivo; las funciones de sincronización e imágenes usan Supabase y requieren conexión a internet.

En el primer inicio, si no hay una sesión de Supabase guardada, la app muestra el acceso superpuesto para iniciar sesión. Después, el acceso a la cuenta queda en **Settings** en la navegación inferior.

El icono de launcher de Android está en `app/src/main/res/mipmap-nodpi/ic_launcher.png` y se configura desde el manifiesto de la aplicación.

## Abrir y generar el APK

1. Instala Android Studio y un JDK 17.
2. Abre en Android Studio la carpeta `android` de este proyecto.
3. Acepta la sincronización de Gradle e instala Android SDK 35 si Android Studio lo solicita.
4. Para probarla, conecta un dispositivo Android o crea un emulador y pulsa **Run**.
5. Para generar el APK de depuración, selecciona **Build > Build Bundle(s) / APK(s) > Build APK(s)**. Android Studio mostrará dónde guardó el APK.

## Generar el APK en GitHub Actions

El workflow `.github/workflows/android-apk.yml` compila automáticamente un APK de depuración cada vez que se suben cambios a GitHub. También se puede ejecutar manualmente desde la pestaña **Actions**.

1. Sube el proyecto completo a un repositorio de GitHub, conservando la carpeta `android` y `.github/workflows/android-apk.yml` en la raíz.
2. Abre la pestaña **Actions** del repositorio y selecciona **Build Android APK** para comprobar el resultado de la compilación.
3. Cuando termine correctamente, abre esa ejecución y descarga el artefacto **quick-notes-debug-apk** en la sección **Artifacts**.
4. Descomprime el artefacto: contiene `app-debug.apk`, que puedes instalar para probar la app.

Este APK de depuración sirve para pruebas. Para distribuir una versión de producción hará falta crear una clave de firma y configurar un build `release` firmado.

## Actualizar la app web

El HTML que Android empaqueta está en `app/src/main/assets/Notes.html`. Si haces cambios en el archivo web original `../Notes.html`, copia la versión actualizada a esa ubicación antes de volver a compilar.
