import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:auxiliomecanico_movil/core/constantes/constantes_aplicacion.dart';
import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';
import 'package:auxiliomecanico_movil/features/notificaciones/servicios/notificaciones_service.dart';

/// Proveedor de autenticación con Provider
class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  String? _token;
  String? _refreshToken;
  User? _user;
  bool _isLoading = true;
  String? _error;
  bool _notificationListenersInitialized = false;

  // Getters
  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Obtiene el rol del usuario actual
  String? get userRole => _user?.role?.toString().toLowerCase().trim();

  /// Obtiene si el usuario es admin
  bool get isAdmin => userRole == AppConstants.roleAdmin;

  /// Obtiene si el usuario autenticado es cliente
  bool get isClient => userRole == 'cliente';

  User _mergeProfileWithTokenRole(
    User profile,
    Map<String, dynamic> tokenData,
  ) {
    final tokenRole = tokenData['role']?.toString().toLowerCase().trim();
    final tokenIsAdmin =
        tokenData['is_admin'] == true || tokenData['es_admin'] == true;

    final effectiveRole =
        (tokenRole == AppConstants.roleAdmin ||
            tokenRole == 'cliente' ||
            tokenRole == AppConstants.roleEmployee)
        ? tokenRole!
        : (tokenIsAdmin ? AppConstants.roleAdmin : profile.role);

    if (profile.role == effectiveRole) {
      return profile;
    }

    return User(
      id: profile.id,
      username: profile.username,
      email: profile.email,
      firstName: profile.firstName,
      lastName: profile.lastName,
      role: effectiveRole,
      empresaId: profile.empresaId,
      clienteId: profile.clienteId,
      isActive: profile.isActive,
      createdAt: profile.createdAt,
    );
  }

  AuthProvider() {
    _initializeAuth().catchError((e) {
      debugPrint('❌ FATAL: Error en _initializeAuth: $e');
      _isLoading = false;
      _error = 'Error crítico inicializando autenticación';
      debugPrint('[AuthProvider] constructor catch -> isLoading: $_isLoading');
      debugPrint(
        '[AuthProvider] constructor catch -> isAuthenticated: ${isAuthenticated}',
      );
      debugPrint('[AuthProvider] constructor catch -> userRole: ${userRole}');
      notifyListeners();
    });
  }

  /// Inicializa la autenticación verificando si hay un token guardado
  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔑 Iniciando lectura de tokens almacenados...');
      _token = await _storage.read(key: AppConstants.storageKeyToken);
      _refreshToken = await _storage.read(
        key: AppConstants.storageKeyRefreshToken,
      );

      if (_token != null && !Jwt.isExpired(_token!)) {
        debugPrint('✅ Token válido encontrado');
        // Token válido, decodificar usuario del token
        final decodedToken = Jwt.parseJwt(_token!);
        debugPrint('Token decodificado: $decodedToken');

        // Obtener perfil completo del usuario desde el backend
        try {
          debugPrint('🌐 Conectando al backend para obtener perfil...');
          final apiService = ApiService(token: _token);
          final profile = await apiService.getProfile().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout obteniendo perfil (10s)');
            },
          );

          _user = _mergeProfileWithTokenRole(profile, decodedToken);
          debugPrint('✅ Usuario obtenido del backend: $_user');
          debugPrint('✅ Rol del usuario: ${_user?.role}');
        } catch (e) {
          debugPrint('⚠️ Error al obtener perfil: $e');
          // Si no se puede obtener el perfil, hacer logout sin fallar
          try {
            await logout();
          } catch (logoutError) {
            debugPrint('⚠️ Error durante logout: $logoutError');
          }
        }
      } else {
        debugPrint('ℹ️ Sin token válido - usuario no autenticado');
        // Token expirado o no existe
        _token = null;
        _refreshToken = null;
        _user = null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error inicializando autenticación: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Error al inicializar sesión: ${e.toString()}';
      // No rethrow - solo continuar
    } finally {
      _isLoading = false;
      debugPrint(
        '[AuthProvider] _initializeAuth finally -> isLoading: $_isLoading',
      );
      debugPrint(
        '[AuthProvider] _initializeAuth finally -> isAuthenticated: ${isAuthenticated}',
      );
      debugPrint(
        '[AuthProvider] _initializeAuth finally -> userRole: ${userRole}',
      );
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ Error notificando listeners: $e');
      }
    }
  }

  /// Realizar login con usuario y contraseña
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final response = await apiService.login(
        username: username,
        password: password,
      );

      _token = response['access'];
      _refreshToken = response.containsKey('refresh')
          ? response['refresh']
          : null;

      // Verificar que el token no esté expirado
      if (_token == null || Jwt.isExpired(_token!)) {
        throw Exception('Token inválido');
      }

      // Guardar tokens en almacenamiento seguro
      await _storage.write(key: AppConstants.storageKeyToken, value: _token!);
      if (_refreshToken != null) {
        await _storage.write(
          key: AppConstants.storageKeyRefreshToken,
          value: _refreshToken!,
        );
      }

      // Obtener perfil del usuario
      final authApiService = ApiService(token: _token);
      final decodedToken = Jwt.parseJwt(_token!);
      _user = _mergeProfileWithTokenRole(
        await authApiService.getProfile(),
        decodedToken,
      );
      debugPrint('✅ Login exitoso. Usuario: $_user');
      debugPrint('✅ Rol detectado: ${_user?.role}');

      // Obtener FCM token y enviarlo al backend
      await _sendFcmToken(authApiService);

      return true;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _token = null;
      _refreshToken = null;
      _user = null;
      debugPrint('⚠️ Login fallido: $e');
      return false;
    } finally {
      _isLoading = false;
      debugPrint('[AuthProvider] isLoading: $_isLoading');
      debugPrint('[AuthProvider] isAuthenticated: ${isAuthenticated}');
      debugPrint('[AuthProvider] userRole: ${userRole}');
      notifyListeners();
    }
  }

  /// Registrar un cliente y dejarlo autenticado
  Future<bool> registerClient({
    required String nombre,
    required String username,
    required String password,
    String? email,
    String? telefono,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final response = await apiService.registerClient(
        nombre: nombre,
        username: username,
        password: password,
        email: email,
        telefono: telefono,
      );

      _token = response['access'];
      _refreshToken = response.containsKey('refresh')
          ? response['refresh']
          : null;

      if (_token == null || Jwt.isExpired(_token!)) {
        throw Exception('Token inválido');
      }

      await _storage.write(key: AppConstants.storageKeyToken, value: _token!);
      if (_refreshToken != null) {
        await _storage.write(
          key: AppConstants.storageKeyRefreshToken,
          value: _refreshToken!,
        );
      }

      final authApiService = ApiService(token: _token);
      final decodedToken = Jwt.parseJwt(_token!);
      _user = _mergeProfileWithTokenRole(
        await authApiService.getProfile(),
        decodedToken,
      );

      return true;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _token = null;
      _refreshToken = null;
      _user = null;
      debugPrint('⚠️ Registro fallido: $e');
      return false;
    } finally {
      _isLoading = false;
      debugPrint(
        '[AuthProvider] _initializeAuth finally -> isLoading: $_isLoading',
      );
      debugPrint(
        '[AuthProvider] _initializeAuth finally -> isAuthenticated: $isAuthenticated',
      );
      debugPrint(
        '[AuthProvider] _initializeAuth finally -> userRole: $userRole',
      );
      debugPrint('[AuthProvider] notifyListeners ejecutado después de init');
      notifyListeners();
    }
  }

  /// Realizar logout
  Future<void> logout() async {
    try {
      if (_token != null) {
        final apiService = ApiService(token: _token);
        await apiService.logout();
      }
    } catch (e) {
      print('Error en logout remoto: $e');
    } finally {
      // Limpiar datos locales
      await _storage.delete(key: AppConstants.storageKeyToken);
      await _storage.delete(key: AppConstants.storageKeyRefreshToken);
      await _storage.delete(key: AppConstants.storageKeyUser);

      _token = null;
      _refreshToken = null;
      _user = null;
      _error = null;
      _isLoading = false;
      debugPrint('[AuthProvider] logout -> isLoading: $_isLoading');
      debugPrint(
        '[AuthProvider] logout -> isAuthenticated: ${isAuthenticated}',
      );
      debugPrint('[AuthProvider] logout -> userRole: ${userRole}');
      notifyListeners();
    }
  }

  /// Obtener FCM token y enviarlo al backend
  Future<void> _sendFcmToken(ApiService apiService) async {
    try {
      final fcmToken = await NotificationService.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await apiService.updateFcmToken(fcmToken);
        print('[AuthProvider] FCM token enviado al backend');
      }
    } catch (e) {
      print('[AuthProvider] Error enviando FCM token: $e');
      // No fallar el login si hay error con FCM
    }
  }

  /// Inicializar listeners de notificaciones
  void initializeNotificationListeners(BuildContext context) {
    if (_notificationListenersInitialized) {
      return;
    }
    NotificationService.initializeNotifications(context, (incidentId) {
      _handleIncidentNotification(incidentId);
    });
    _notificationListenersInitialized = true;
  }

  /// Manejar notificación de incidente
  void _handleIncidentNotification(String? incidentId) {
    if (incidentId != null) {
      print('[AuthProvider] Notificación de incidente recibida: $incidentId');
      // Notificar a los listeners que hay una nueva notificación
      notifyListeners();
    }
  }

  /// Obtener mensaje de error legible
  String _getErrorMessage(String error) {
    if (error.contains('Credenciales inválidas')) {
      return 'Usuario o contraseña incorrectos';
    } else if (error.contains('Connection refused') ||
        error.contains('Failed host lookup')) {
      return 'No se puede conectar al servidor';
    } else if (error.contains('Token inválido')) {
      return 'Token de autenticación inválido';
    } else if (error.contains('timed out')) {
      return 'Tiempo de espera agotado';
    } else {
      return 'Error: ${error.length > 50 ? error.substring(0, 50) + '...' : error}';
    }
  }

  /// Limpiar mensaje de error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
