import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';

class EmpleadoService {
  final ApiService _api;
  EmpleadoService(this._api);

  Future<List<User>> getEmployees() async {
    return _api.getEmployees();
  }

  Future<User> createEmployee({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String cargoId,
    required String empresaId,
  }) async {
    return _api.createEmployee(
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      cargoId: cargoId,
      empresaId: empresaId,
    );
  }

  Future<User> updateEmployee({
    required int id,
    required String email,
    String? firstName,
    String? lastName,
    String? cargoId,
  }) async {
    return _api.updateEmployee(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      cargoId: cargoId,
    );
  }

  Future<void> deleteEmployee(int id) async {
    return _api.deleteEmployee(id);
  }
}
