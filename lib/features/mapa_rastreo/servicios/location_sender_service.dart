import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'websocket_tracking_service.dart';

class LocationSenderService {
  final WebSocketTrackingService _wsService;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  LocationSenderService(this._wsService);

  bool get isTracking => _isTracking;

  /// Solicita permisos de ubicación e inicia la transmisión de coordenadas al WebSocket.
  Future<bool> startTracking(String incidentId) async {
    if (_isTracking) return true;

    // Verificar si el servicio de ubicación está habilitado a nivel dispositivo
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('El servicio de localización está desactivado en el dispositivo.');
      return false;
    }

    // Comprobar y solicitar permisos de ubicación
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permiso de geolocalización rechazado.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permiso de geolocalización denegado permanentemente.');
      return false;
    }

    // Iniciar conexión WebSocket
    _wsService.connect(incidentId);

    // Ajustes de localización: Alta precisión y filtros de distancia (5 metros)
    // para optimizar el consumo de batería y ancho de banda
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, 
    );

    _isTracking = true;

    // Suscribirse al flujo de coordenadas
    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_isTracking) {
          _wsService.sendLocation(position.latitude, position.longitude);
        }
      },
      onError: (error) {
        print('Error en flujo de geolocalizador: $error');
        stopTracking();
      },
    );

    return true;
  }

  /// Cancela la suscripción de ubicación y cierra el WebSocket.
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _wsService.disconnect();
    print('Transmisión de ubicación en segundo plano detenida.');
  }
}
