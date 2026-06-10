import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/servicios/autenticacion_service.dart';
import 'package:auxiliomecanico_movil/features/perfil_tecnico/servicios/empleado_service.dart';
import 'package:auxiliomecanico_movil/features/clientes/servicios/cliente_service.dart';
import 'package:auxiliomecanico_movil/features/incidentes/servicios/incidente_service.dart';

/// Cliente central que crea servicios con el token actual
class ApiClient {
  String? _token;

  ApiClient({String? token}) : _token = token;

  void setToken(String? token) {
    _token = token;
  }

  AuthService auth() => AuthService(ApiService(token: _token));
  EmpleadoService empleado() => EmpleadoService(ApiService(token: _token));
  ClienteService cliente() => ClienteService(ApiService(token: _token));
  IncidenteService incidente() => IncidenteService(token: _token);
}
