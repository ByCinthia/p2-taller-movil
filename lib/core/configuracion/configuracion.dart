/// Archivo de configuración para desarrollo local
///
/// Este archivo contiene configuraciones útiles para desarrollo
/// y pruebas de la aplicación móvil

library config;

// ==================== DESARROLLO ====================

/// URL base para desarrollo en emulador Android
const String DEV_BASE_URL_ANDROID = 'https://p2-taller-back.duckdns.org';

/// URL base para desarrollo en dispositivo físico
/// Usa la IP Wi-Fi local del PC para que el móvil en la misma red pueda acceder
const String DEV_BASE_URL_PHYSICAL = 'https://p2-taller-back.duckdns.org';

/// URL base para desarrollo en iOS
const String DEV_BASE_URL_IOS = 'https://p2-taller-back.duckdns.org';

// ==================== PRODUCCIÓN ====================

/// URL base para producción
const String PROD_BASE_URL = 'https://p2-taller-back.duckdns.org';

// ==================== CONFIGURACIÓN ====================

/// Habilitar logs detallados de API
const bool ENABLE_API_LOGS = true;

/// Habilitar modo debug en pantalla de login
const bool SHOW_DEBUG_LOGIN_INFO = true;

/// Timeout para requests (en segundos)
const int REQUEST_TIMEOUT = 30;

// ==================== CREDENCIALES DE PRUEBA ====================

/// Usuario de prueba admin
const String TEST_ADMIN_USERNAME = 'admin';
const String TEST_ADMIN_PASSWORD = '123';

/// Usuario de prueba empleado
const String TEST_EMPLOYEE_USERNAME = 'empleado';
const String TEST_EMPLOYEE_PASSWORD = '123';
