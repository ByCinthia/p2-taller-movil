import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constantes/constantes_aplicacion.dart';

class WebSocketTrackingService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _currentIncidentId;

  // StreamController para notificar el estado de conexión a la UI o controladores
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _statusController.stream;

  bool get isConnected => _isConnected;

  /// Establece conexión WebSocket con el backend para emitir coordenadas.
  void connect(String incidentId) {
    if (_currentIncidentId == incidentId && _isConnected && _channel != null) {
      return;
    }

    disconnect(); // Limpiar conexiones existentes
    _currentIncidentId = incidentId;

    // Traducir baseUrl http/https a ws/wss
    final baseUrl = AppConstants.baseUrl;
    final wsProtocol = baseUrl.startsWith('https://') ? 'wss://' : 'ws://';
    final cleanBase = baseUrl.replaceFirst(RegExp(r'https?://'), '');
    final wsUrl = '$wsProtocol$cleanBase/api/ws/tracking/$incidentId/tecnico';

    print('Conectando a WebSocket de rastreo: $wsUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _statusController.add(true);

      // Escuchar eventos o errores del canal de comunicación
      _channel!.stream.listen(
        (message) {
          if (message == 'pong') {
            print('Recibido pong del servidor');
          } else {
            print('Mensaje del servidor: $message');
          }
        },
        onError: (error) {
          print('Error en WebSocket de rastreo: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('Conexión de rastreo WebSocket finalizada.');
          _handleDisconnection();
        },
      );

      // Iniciar el envío periódico de latidos (ping) para mantener vivo el canal
      _startPing();
    } catch (e) {
      print('Excepción al conectar con WebSocket: $e');
      _handleDisconnection();
    }
  }

  /// Transmite la ubicación actual al servidor mediante un payload JSON.
  bool sendLocation(double latitude, double longitude) {
    if (!_isConnected || _channel == null || _currentIncidentId == null) {
      print('Imposible transmitir: WebSocket desconectado.');
      return false;
    }

    try {
      final payload = {
        'latitud': latitude,
        'longitud': longitude,
        'incidente_id': _currentIncidentId,
      };

      _channel!.sink.add(jsonEncode(payload));
      print('Ubicación transmitida: ($latitude, $longitude) para incidente: $_currentIncidentId');
      return true;
    } catch (e) {
      print('Error al enviar coordenadas por WebSocket: $e');
      return false;
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add('ping');
      }
    });
  }

  void _handleDisconnection() {
    _isConnected = false;
    _statusController.add(false);
    _pingTimer?.cancel();

    // Intentar reconectar si el incidente actual sigue activo
    if (_currentIncidentId != null) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        if (_currentIncidentId != null && !_isConnected) {
          print('Reintentando conectar a WebSocket de rastreo...');
          connect(_currentIncidentId!);
        }
      });
    }
  }

  /// Desconecta y libera recursos.
  void disconnect() {
    _currentIncidentId = null;
    _isConnected = false;
    _statusController.add(false);
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  /// Cierra permanentemente el controller.
  void dispose() {
    disconnect();
    _statusController.close();
  }
}
