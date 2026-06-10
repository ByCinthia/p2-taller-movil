import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';

class AuthService {
  final ApiService _api;
  AuthService(this._api);

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) {
    return _api.login(username: username, password: password);
  }

  Future<Map<String, dynamic>> registerClient({
    required String nombre,
    required String username,
    required String password,
    String? email,
    String? telefono,
  }) {
    return _api.registerClient(
      nombre: nombre,
      username: username,
      password: password,
      email: email,
      telefono: telefono,
    );
  }

  Future<User> getProfile() {
    return _api.getProfile();
  }
}
