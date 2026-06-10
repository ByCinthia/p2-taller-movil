import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';

/// Proveedor para manejar la ubicación del técnico y sincronizarla con el backend
class LocationProvider extends ChangeNotifier {
  final ApiService apiService;

  LocationProvider({required this.apiService});

  Position? _currentPosition;
  bool _isUpdatingLocation = false;
  String? _locationError;
  DateTime? _lastLocationUpdate;

  Position? get currentPosition => _currentPosition;
  bool get isUpdatingLocation => _isUpdatingLocation;
  String? get locationError => _locationError;
  DateTime? get lastLocationUpdate => _lastLocationUpdate;

  /// Obtener la ubicación actual del dispositivo
  Future<Position?> getCurrentLocation() async {
    try {
      _locationError = null;
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        _locationError = 'Permiso de ubicación denegado';
        notifyListeners();
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Actualizar si se mueve más de 10 metros
        ),
      );

      _currentPosition = position;
      _lastLocationUpdate = DateTime.now();
      notifyListeners();
      return position;
    } catch (e) {
      _locationError = 'Error al obtener ubicación: $e';
      notifyListeners();
      return null;
    }
  }

  /// Enviar la ubicación actual al backend
  Future<bool> actualizarUbicacionEnBackend() async {
    try {
      if (_currentPosition == null) {
        _locationError = 'Ubicación no disponible';
        notifyListeners();
        return false;
      }

      _isUpdatingLocation = true;
      _locationError = null;
      notifyListeners();

      await apiService.actualizarMiUbicacion(
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
      );

      _isUpdatingLocation = false;
      _lastLocationUpdate = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdatingLocation = false;
      _locationError = 'Error al actualizar ubicación: $e';
      notifyListeners();
      return false;
    }
  }

  /// Obtener y actualizar la ubicación en una sola operación
  Future<bool> obtenerYActualizarUbicacion() async {
    final position = await getCurrentLocation();
    if (position == null) {
      return false;
    }
    return await actualizarUbicacionEnBackend();
  }

  /// Iniciar actualización periódica de ubicación (por ejemplo, cada 30 segundos)
  Future<void> iniciarActualizacionPeriodica({
    Duration intervalo = const Duration(seconds: 30),
  }) async {
    // Obtener ubicación inicial
    await obtenerYActualizarUbicacion();

    // Configurar stream de posición para cambios en tiempo real
    final positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Actualizar cada 50 metros
      ),
    );

    positionStream.listen((Position position) {
      _currentPosition = position;
      _lastLocationUpdate = DateTime.now();
      notifyListeners();

      // Enviar al backend
      actualizarUbicacionEnBackend();
    });
  }

  /// Verificar permisos de ubicación
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Limpiar errores
  void clearError() {
    _locationError = null;
    notifyListeners();
  }

  /// Reiniciar el proveedor
  void reset() {
    _currentPosition = null;
    _isUpdatingLocation = false;
    _locationError = null;
    _lastLocationUpdate = null;
    notifyListeners();
  }
}
