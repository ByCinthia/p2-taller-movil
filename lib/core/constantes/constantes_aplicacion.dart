/// Constantes de la aplicación
class AppConstants {
  // URLs base del API
  static const String baseUrl =
      //  'http://10.0.2.2:8000'; // IP para Emulador Android
      'http://192.168.0.15:8000'; // IP Wi-Fi local del PC para usar desde celular físico

  static const String apiPrefix = '/api';
  static const String authEndpoint = '$apiPrefix/auth';
  static const String clientesEndpoint = '$apiPrefix/clientes';
  static const String vehiculosEndpoint = '$apiPrefix/vehiculos';
  static const String empleadosEndpoint = '$apiPrefix/empleados';
  static const String rolesEndpoint = '$apiPrefix/roles';
  static const String permisosEndpoint = '$apiPrefix/permisos';
  static const String notificacionesEndpoint = '$apiPrefix/notificaciones';

  // Claves de almacenamiento seguro
  static const String storageKeyToken = 'auth_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUser = 'user_data';

  // Tiempos
  static const Duration tokenRefreshInterval = Duration(minutes: 5);
  static const Duration requestTimeout = Duration(seconds: 30);

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'empleado';
}
