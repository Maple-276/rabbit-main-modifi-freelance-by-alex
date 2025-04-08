# READMEALEX - Configuración del Proyecto Flutter Restaurant

## Prerequisitos
- Windows 10 o superior
- Mínimo 8GB de RAM
- 10GB de espacio libre en disco

## 1. Instalar Flutter SDK
1. Descargar Flutter SDK 3.24.5 desde [Flutter Archive](https://docs.flutter.dev/release/archive?tab=windows)
2. Extraer el ZIP en un directorio permanente (Ejemplo: `C:\dev\flutter`)
3. Añadir Flutter al PATH del sistema:
   - Buscar "Variables de entorno" en el inicio de Windows
   - En variables de usuario, editar PATH
   - Añadir la ruta completa a `flutter\bin`
   - Aplicar cambios

## 2. Verificar instalación de Flutter
```powershell
flutter --version
flutter doctor
```
- Solucionar problemas identificados por flutter doctor

## 3. Instalar dependencias de desarrollo
1. Instalar [Git](https://git-scm.com/download/win)
2. Instalar [Android Studio](https://developer.android.com/studio)
3. En Android Studio, instalar:
   - Android SDK
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
4. Instalar [VS Code](https://code.visualstudio.com/) (recomendado)
5. Añadir extensiones Flutter y Dart en VS Code

## 4. Configurar el proyecto
1. Clonar el repositorio (si aún no lo has hecho)
2. Abrir la terminal en la carpeta del proyecto
3. Instalar dependencias:
   ```powershell
   flutter pub get
   ```
4. Ejecutar generador de código:
   ```powershell
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
5. Activar DevTools para desarrollo:
   ```powershell
   flutter pub global activate devtools
   ```

## 5. Configurar Firebase
1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Añadir aplicación Android e iOS
3. Descargar y colocar archivos de configuración:
   - Android: `google-services.json` en `/android/app/`
   - iOS: `GoogleService-Info.plist` en `/ios/Runner/`
4. Comprobar que el archivo `.firebaserc` tenga el proyecto correcto

## 6. Configurar Google Maps
1. Crear proyecto en [Google Cloud Console](https://console.cloud.google.com/)
2. Activar APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API
3. Crear clave API con restricciones para Android, iOS y Web
4. Configurar clave API en:
   - Android: `/android/app/src/main/AndroidManifest.xml`
   - iOS: `/ios/Runner/AppDelegate.swift`
   - Web: Archivo correspondiente

## 7. Configurar autenticación social (opcional)
1. Para Google Sign-In:
   - Configurar OAuth en Google Cloud Console
   - Verificar configuración en Firebase Authentication
2. Para Facebook Auth:
   - Crear app en [Facebook Developers](https://developers.facebook.com/)
   - Configurar Firebase Authentication
3. Para Sign in with Apple:
   - Configurar en Apple Developer Portal

## 8. Ejecutar el proyecto
1. Conectar dispositivo o iniciar emulador
2. Ejecutar la aplicación:
   ```powershell
   flutter run
   ```

## 9. Comandos útiles
```powershell
# Limpiar proyecto
flutter clean

# Reconstruir después de limpiar
flutter pub get

# Verificar problemas de código
flutter analyze

# Ejecutar tests
flutter test

# Construir APK
flutter build apk

# Construir app bundle
flutter build appbundle

# Ejecutar en modo web
flutter run -d chrome
```

## 10. Solución de problemas comunes
1. Error "Unable to locate adb": Reinstalar Android SDK Platform-Tools
2. Problemas de Gradle: Actualizar archivo gradle-wrapper.properties
3. Error con Firebase: Verificar versiones en pubspec.yaml vs. configuración Firebase
4. Error con Google Maps: Verificar validez y restricciones de la clave API

## 11. Recursos adicionales
- [Documentación Flutter](https://docs.flutter.dev/)
- [Documentación Firebase](https://firebase.google.com/docs)
- [Guía Google Maps Flutter](https://codelabs.developers.google.com/codelabs/google-maps-in-flutter)
- [Canal YouTube Flutter](https://www.youtube.com/c/flutterdev) 