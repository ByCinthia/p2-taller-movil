# Guía de Configuración y Ejecución - Aplicación Móvil

Esta guía te ayudará a configurar y ejecutar la aplicación móvil Auxilio Mecánico en tu máquina de desarrollo.

## 📋 Requisitos Previos

### Sistema Operativo
- Windows, macOS o Linux

### Software Requerido
- **Flutter 3.8.1 o superior** - [Descargar](https://flutter.dev/docs/get-started/install)
- **Android Studio** (opcional pero recomendado) - [Descargar](https://developer.android.com/studio)
- **Visual Studio Code** o Android Studio para desarrollo
- **Git** para control de versiones

### Para Ejecutar en Android
- Android SDK API 21 o superior
- Emulador de Android configurado **O** dispositivo Android físico

### Para Ejecutar en iOS (solo macOS)
- Xcode 12 o superior
- iOS 12 o superior
- CocoaPods

## 🔧 Pasos de Instalación

### 1. Verificar Instalación de Flutter

```bash
flutter --version
dart --version
```

Deberías ver versiones de Flutter y Dart.

### 2. Navegar a la Carpeta Mobile

```bash
cd c:\Users\HP\OneDrive\Escritorio\AuxilioMecanico_SI2\mobile
```

O en Linux/macOS:
```bash
cd ~/AuxilioMecanico_SI2/mobile
```

### 3. Instalar Dependencias

```bash
flutter clean
flutter pub get
```

Esto descargará todas las dependencias requeridas.

### 4. Verificar Doctor de Flutter

```bash
flutter doctor
```

Debe mostrar todo en verde (✓). Si hay advertencias sobre Android SDK o Xcode, resuelve según tu plataforma.

## 🎯 Configuración de la URL del Backend

### Paso 1: Obtener tu IP Local

**En Windows (PowerShell):**
```powershell
ipconfig
```
Busca "IPv4 Address" en la sección de tu conexión (ej: 192.168.x.x)

**En macOS/Linux:**
```bash
ifconfig
```

### Paso 2: Actualizar Constantes

Abre `lib/core/constants.dart`:

```dart
class AppConstants {
  // Cambia esto según tu entorno:
  
  // Para emulador Android (default):
  static const String baseUrl = 'http://10.0.2.2:8001';
  
  // Para dispositivo físico (reemplaza con tu IP):
  // static const String baseUrl = 'http://192.168.1.100:8001';
  
  // Para iOS Simulator:
  // static const String baseUrl = 'http://localhost:8001';
}
```

## ▶️ Ejecutar la Aplicación

### En Emulador Android

#### 1. Abrir Android Studio
- Abre Android Studio
- Ve a AVD Manager (Virtual Device Manager)
- Inicia un emulador (ej: Pixel 5 API 31)

#### 2. Ejecutar Flutter
```bash
flutter run
```

O especificar el dispositivo:
```bash
flutter devices
flutter run -d emulator-5554
```

### En Dispositivo Android Físico

#### 1. Preparar el Dispositivo
- Habilita "Modo de Desarrollador" (toca 7 veces el número de compilación en Configuración)
- Habilita "Depuración USB"
- Conecta el dispositivo por USB

#### 2. Verificar Conexión
```bash
flutter devices
```

Deberías ver tu dispositivo listado.

#### 3. Ejecutar
```bash
flutter run
```

### En iOS (solo macOS)

```bash
flutter run -d "iPhone 15"
```

O sin especificar dispositivo:
```bash
flutter run
```

## 🧪 Pruebas de Login

### Credenciales de Prueba

**Administrador:**
- Usuario: `admin`
- Contraseña: `123`

**Empleado:**
- Usuario: `empleado`
- Contraseña: `123`

> Nota: Estas credenciales deben existir en tu base de datos del backend

### Verificar Conexión al Backend

1. En la pantalla de login, intenta iniciar sesión
2. Si ves el error "No se puede conectar al servidor":
   - Verifica que el backend está corriendo: `uvicorn app.main:app --reload --port 8001`
   - Verifica la URL correcta en `constants.dart`
   - En emulador, debe ser `10.0.2.2` no `localhost`

3. Si ves "Credenciales inválidas":
   - Las credenciales no existen en el backend
   - Crea un usuario admin en la base de datos

## 🔄 Desarrollo Hot Reload

Una ventaja de Flutter es el Hot Reload - hacer cambios sin reiniciar la app:

```bash
flutter run
```

Luego presiona:
- `r` - Hot reload (recarga rápida)
- `R` - Hot restart (reinicia la app)
- `q` - Salir

## 🐛 Debugging

### Ver Logs en Consola
```bash
flutter logs
```

### Usar DevTools
```bash
flutter pub global activate devtools
devtools
```

Luego abre http://localhost:9100

### Debugger en VS Code
1. Ve a Run -> Start Debugging (F5)
2. Selecciona Flutter
3. Pon breakpoints en el código

## 📁 Estructura de Archivos Creada

```
mobile/
├── lib/
│   ├── core/
│   │   ├── constants.dart      ← EDITAR aquí para cambiar URL
│   │   ├── extensions.dart
│   │   ├── theme.dart
│   │   └── utils.dart
│   ├── data/
│   │   └── api_service.dart
│   ├── models/
│   │   └── user.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── admin/
│   │   │   └── admin_home_screen.dart
│   │   └── employee/
│   │       └── employee_home_screen.dart
│   ├── widgets/
│   │   ├── custom_app_bar.dart
│   │   └── custom_text_field.dart
│   ├── config.dart
│   └── main.dart               ← Punto de entrada
├── pubspec.yaml                ← Dependencias
├── .gitignore
├── README.md
└── SETUP.md                    ← Este archivo
```

## 🚨 Solución de Problemas Comunes

### "Flutter command not found"
```bash
# Añade Flutter al PATH (Windows - PowerShell):
$env:PATH += ";C:\path\to\flutter\bin"

# O edita las variables de entorno del sistema
```

### "No devices found"
- Verifica que el emulador está abierto: `flutter devices`
- Conecta el dispositivo Android por USB
- En macOS, abre Xcode: `open ios/Runner.xcworkspace`

### "Gradle error"
```bash
flutter clean
flutter pub get
flutter run
```

### "HTTP Connection Refused"
- El backend no está corriendo en puerto 8001
- La IP en `constants.dart` es incorrecta
- Firewall está bloqueando la conexión

### "Invalid JWT"
- Token ha expirado
- Backend fue reiniciado
- Solución: Limpiar la app: `flutter clean && flutter run`

## 📱 Emulador Android - Primeros Pasos

### Crear un Emulador

1. Abre Android Studio
2. Tools → Device Manager → Create Device
3. Selecciona "Pixel 5" o similar
4. Elige API 31 o superior
5. Haz clic en "Create"

### Iniciar el Emulador

```bash
emulator -avd Pixel_5_API_31
```

O desde Android Studio: Device Manager → Play

### Verificar IP en Emulador

```bash
adb shell getprop ro.kernel.android.bootloader
```

Para emulador es siempre `10.0.2.2` para acceder a localhost.

## 🔗 Verificar Conexión Backend-Mobile

### Test de API desde Mobile

Abre la consola de Flutter:
```bash
flutter run
```

Intenta login, deberías ver en los logs:
```
I/flutter (12345): Token decodificado: {...}
```

Si ves errores de conexión, verifica:
1. Backend corriendo: `curl http://localhost:8001/api/health`
2. URL correcta en `constants.dart`
3. Emulador/Dispositivo puede alcanzar la red

## 📚 Próximos Pasos

1. **Implementar pantallas adicionales** - Cargos, Roles, Permisos
2. **Agregar validaciones avanzadas** - Campos de formulario más complejos
3. **Notificaciones Push** - Usar Firebase Cloud Messaging
4. **Base de datos local** - SQLite para modo offline
5. **Tests** - Unit y Widget tests

## 📞 Contacto y Ayuda

Para problemas específicos de Flutter:
- [Flutter Documentation](https://flutter.dev/docs)
- [Stack Overflow - Flutter tag](https://stackoverflow.com/questions/tagged/flutter)

Para problemas del proyecto:
- Revisa los logs: `flutter logs`
- Verifica la consola del backend
- Comprueba la conexión de red
