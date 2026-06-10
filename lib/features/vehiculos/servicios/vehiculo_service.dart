import 'package:flutter/foundation.dart';
import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/modelos/vehiculo.dart';

class VehiculoService {
  final ApiService _api;

  VehiculoService({String? token}) : _api = ApiService(token: token);

  Future<List<Vehicle>> getMisVehiculos() async {
    return _api.getMyVehicles();
  }

  Future<Vehicle> registrarVehiculo(Map<String, dynamic> data) async {
    return _api.createMyVehicle(
      marca: data['marca'] ?? '',
      modelo: data['modelo'] ?? '',
      placa: data['placa'] ?? '',
      anio: data['anio'] as int?,
      principal: data['principal'] == true,
    );
  }

  Future<Vehicle> actualizarVehiculo(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _api.updateVehicle(id: id, body: data);
  }

  Future<void> eliminarVehiculo(String id) async {
    return _api.deleteMyVehicle(id);
  }
}
