import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auxiliomecanico_movil/core/constantes/constantes_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/perfil_tecnico/modelos/asignacion_empleado.dart';
import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/modelos/vehiculo.dart';

/// Servicio API para comunicarse con el backend FastAPI
class ApiService {
  final String? _token;

  ApiService({String? token}) : _token = token;

  /// Headers comunes para todas las requests
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Login - POST /api/auth/login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.authEndpoint}/login',
            ),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else {
        throw Exception('Error de login: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Registro de cliente - POST /register/client/
  Future<Map<String, dynamic>> registerClient({
    required String nombre,
    required String username,
    required String password,
    String? email,
    String? telefono,
  }) async {
    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/register/client/'),
          headers: _getHeaders(includeAuth: false),
          body: jsonEncode({
            'nombre': nombre,
            'username': username,
            'password': password,
            'email': email,
            'telefono': telefono,
          }),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 400) {
      final detail = jsonDecode(response.body);
      throw Exception(
        detail['detail']?.toString() ?? 'No se pudo registrar el cliente',
      );
    }
    throw Exception('Error de registro: ${response.statusCode}');
  }

  /// Obtener perfil del usuario autenticado - GET /api/auth/me
  Future<User> getProfile() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}/me'),
            headers: _getHeaders(),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        throw Exception('Error al obtener perfil: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener la empresa del usuario autenticado - GET /api/empresa/me
  Future<Map<String, dynamic>> getMyEmpresa() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/api/empresa/me'),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener mi empresa: ${response.statusCode}');
  }

  /// Obtener el perfil completo del empleado autenticado - GET /api/empleados/me/
  Future<Map<String, dynamic>> getMyEmployeeProfile() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.empleadosEndpoint}/me/'),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      throw Exception('El usuario no está asociado a un empleado');
    }
    if (response.statusCode == 401) {
      throw Exception('Token inválido o expirado');
    }
    throw Exception('Error al obtener perfil de empleado: ${response.statusCode}');
  }

  Future<List<Vehicle>> getMyVehicles() async {
    final response = await http
        .get(
          Uri.parse(
            '${AppConstants.baseUrl}${AppConstants.clientesEndpoint}/me/vehiculos',
          ),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleListResponse<Vehicle>(
      response,
      (item) => Vehicle.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Obtener notificaciones del usuario autenticado - GET /api/notificaciones/me/
  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.notificacionesEndpoint}/me/'),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[]);
      return items.map((item) => (item as Map).cast<String, dynamic>()).toList();
    }

    if (response.statusCode == 401) {
      throw Exception('No autorizado (401)');
    }

    throw Exception('Error al obtener notificaciones: ${response.statusCode}');
  }

  /// Marcar notificación como leída - PATCH /api/notificaciones/{id}/leer
  Future<Map<String, dynamic>> markNotificationAsRead(String id) async {
    final response = await http
        .patch(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.notificacionesEndpoint}/$id/leer'),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Error al marcar notificación como leída: ${response.statusCode}');
  }

  /// Obtener asignaciones del empleado autenticado - GET /api/empleados/me/asignaciones
  /// Devuelve una lista de mapas con los datos de las asignaciones/incidentes.
  Future<List<Map<String, dynamic>>> getMyAsignaciones() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.empleadosEndpoint}/me/asignaciones'),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    _log('getMyAsignaciones status=${response.statusCode} body=${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    if (response.statusCode == 401) throw Exception('No autorizado (401)');
    if (response.statusCode >= 500) throw Exception('Error servidor (${response.statusCode})');
    throw Exception('Error al obtener asignaciones: ${response.statusCode}');
  }

  /// Obtener todos los vehículos - GET /api/vehiculos
  /// Requiere permisos (admin/operativo)
  Future<List<Vehicle>> getAllVehicles() async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/api/vehiculos'),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 403) {
      throw Exception('No tienes permiso para acceder a esta lista');
    }

    throw Exception('Error al obtener vehículos: ${response.statusCode}');
  }

  Future<Vehicle> createMyVehicle({
    required String marca,
    required String modelo,
    required String placa,
    int? anio,
    bool principal = false,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '${AppConstants.baseUrl}${AppConstants.clientesEndpoint}/me/vehiculos',
          ),
          headers: _getHeaders(),
          body: jsonEncode({
            'marca': marca,
            'modelo': modelo,
            'placa': placa,
            'anio': anio,
            'principal': principal,
          }),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 201) {
      return Vehicle.fromJson(jsonDecode(response.body));
    }
    return _handleResponse<Vehicle>(response, (body) => Vehicle.fromJson(body));
  }

  Future<Vehicle> updateVehicle({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .put(
          Uri.parse(
            '${AppConstants.baseUrl}${AppConstants.vehiculosEndpoint}/$id/',
          ),
          headers: _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse<Vehicle>(response, (b) => Vehicle.fromJson(b));
  }

  Future<void> deleteMyVehicle(String id) async {
    final response = await http
        .delete(
          Uri.parse(
            '${AppConstants.baseUrl}${AppConstants.clientesEndpoint}/me/vehiculos/$id',
          ),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    if (response.statusCode == 204 || response.statusCode == 200) return;
    _log('deleteMyVehicle status=${response.statusCode} body=${response.body}');
    throw Exception('Error al eliminar vehículo: ${response.statusCode}');
  }

  // Incidentes
  Future<Map<String, dynamic>> createIncidente(
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/api/incidentes/'),
          headers: _getHeaders(),
          body: jsonEncode(payload),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse<Map<String, dynamic>>(
      response,
      (b) => b as Map<String, dynamic>,
    );
  }

  /// Actualizar FCM token - PATCH /api/auth/fcm-token
  Future<Map<String, dynamic>> updateFcmToken(String token) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${AppConstants.baseUrl}/api/auth/fcm-token'),
            headers: _getHeaders(),
            body: jsonEncode({'fcm_token': token}),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado');
      } else {
        throw Exception(
          'Error al actualizar FCM token: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log('Error en updateFcmToken: $e');
      rethrow;
    }
  }

  // Helpers
  void _log(String msg) {
    // simple debug print
    // ignore: avoid_print
    print('[ApiService] $msg');
  }

  T _parseBody<T>(String body) {
    if (body.isEmpty) return {} as T;
    return jsonDecode(body) as T;
  }

  dynamic _handleResponse<T>(
    http.Response response,
    T Function(dynamic body) mapper,
  ) {
    _log('response ${response.statusCode} ${response.body}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final parsed = _parseBody(response.body);
      return mapper(parsed);
    }
    if (response.statusCode == 401) throw Exception('No autorizado (401)');
    if (response.statusCode == 422)
      throw Exception('Datos inválidos (422): ${response.body}');
    if (response.statusCode >= 500)
      throw Exception('Error servidor (${response.statusCode})');
    throw Exception('Error en la petición: ${response.statusCode}');
  }

  List<T> _handleListResponse<T>(
    http.Response response,
    T Function(dynamic item) mapper,
  ) {
    _log('list response ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => mapper(e)).toList();
    }
    if (response.statusCode == 401) throw Exception('No autorizado (401)');
    if (response.statusCode >= 500)
      throw Exception('Error servidor (${response.statusCode})');
    throw Exception('Error al obtener lista: ${response.statusCode}');
  }

  /// Obtener lista de empleados - GET /api/empleados
  /// Solo para usuarios con permiso
  Future<List<User>> getEmployees() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.empleadosEndpoint}',
            ),
            headers: _getHeaders(),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para acceder');
      } else {
        throw Exception('Error al obtener empleados: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener empleados asignables preservando el ID real del empleado.
  Future<List<EmployeeAssignment>> getAssignableEmployees() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}${AppConstants.empleadosEndpoint}'),
            headers: _getHeaders(),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => EmployeeAssignment.fromJson(e as Map<String, dynamic>))
            .where((employee) => employee.id.isNotEmpty)
            .toList();
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para acceder');
      } else {
        throw Exception('Error al obtener empleados: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener lista de servicios - GET /api/servicios/
  Future<List<Map<String, dynamic>>> getServicios() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/api/servicios/'),
            headers: _getHeaders(),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para acceder a los servicios');
      } else {
        throw Exception('Error al obtener servicios: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Asignar técnico/servicio a un incidente - POST /api/incidentes/{id}/asignacion
  Future<Map<String, dynamic>> assignTecnico(String incidenteId, Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/api/incidentes/$incidenteId/asignacion'),
            headers: _getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 403) {
        throw Exception('No tienes permiso para asignar solicitudes');
      }

      throw Exception('Error al asignar técnico: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener detalle de un empleado - GET /api/empleados/{id}
  Future<User> getEmployee(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.empleadosEndpoint}/$id',
            ),
            headers: _getHeaders(),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Empleado no encontrado');
      } else {
        throw Exception('Error al obtener empleado: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener detalle de un incidente - GET /api/incidentes/{id}/
  Future<Map<String, dynamic>> getIncidente(String id) async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/api/incidentes/$id/'),
          headers: _getHeaders(),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse<Map<String, dynamic>>(
      response,
      (b) => b as Map<String, dynamic>,
    );
  }

  /// Actualizar solo el estado de un incidente - PATCH /api/incidentes/{id}/estado
  /// Opcionalmente incluir latitud y longitud cuando el estado es "en_proceso"
  Future<Map<String, dynamic>> updateIncidenteEstado(
    String id,
    String estado, {
    double? latitud,
    double? longitud,
  }) async {
    final body = <String, dynamic>{'estado': estado};
    if (latitud != null) body['latitud'] = latitud;
    if (longitud != null) body['longitud'] = longitud;

    final response = await http
        .patch(
          Uri.parse('${AppConstants.baseUrl}/api/incidentes/$id/estado'),
          headers: _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(AppConstants.requestTimeout);

    return _handleResponse<Map<String, dynamic>>(
      response,
      (b) => b as Map<String, dynamic>,
    );
  }

  /// Crear un nuevo empleado - POST /api/empleados
  Future<User> createEmployee({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String cargoId,
    required String empresaId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.empleadosEndpoint}',
            ),
            headers: _getHeaders(),
            body: jsonEncode({
              'username': username,
              'email': email,
              'first_name': firstName,
              'last_name': lastName,
              'cargo_id': cargoId,
              'empresa_id': empresaId,
            }),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear empleado: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar empleado - PUT /api/empleados/{id}
  Future<User> updateEmployee({
    required int id,
    required String email,
    String? firstName,
    String? lastName,
    String? cargoId,
  }) async {
    try {
      final body = {'email': email};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (cargoId != null) body['cargo_id'] = cargoId;

      final response = await http
          .put(
            Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.empleadosEndpoint}/$id',
            ),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar empleado: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar empleado - DELETE /api/empleados/{id}
  Future<void> deleteEmployee(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.empleadosEndpoint}/$id',
            ),
            headers: _getHeaders(),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Error al eliminar empleado: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar ubicación del técnico - PATCH /incidentes/tecnicos/mi-ubicacion
  /// Llamado periódicamente para compartir posición GPS con el backend
  Future<Map<String, dynamic>> actualizarMiUbicacion({
    required double latitud,
    required double longitud,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
              '${AppConstants.baseUrl}/api/incidentes/tecnicos/mi-ubicacion',
            ),
            headers: _getHeaders(),
            body: jsonEncode({
              'latitud': latitud,
              'longitud': longitud,
            }),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Error al actualizar ubicación: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout - POST /api/auth/logout
  Future<void> logout() async {
    try {
      await http
          .post(
            Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.authEndpoint}/logout',
            ),
            headers: _getHeaders(),
          )
          .timeout(AppConstants.requestTimeout);
    } catch (e) {
      // El logout siempre se considera éxito local aunque falle el backend
      print('Logout error: $e');
    }
  }
}
