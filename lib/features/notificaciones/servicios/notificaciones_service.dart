import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static FirebaseMessaging? _firebaseMessaging;
  static bool _listenersInitialized = false;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _localNotificationsInitialized = false;

  static FirebaseMessaging? _messagingOrNull() {
    try {
      _firebaseMessaging ??= FirebaseMessaging.instance;
      return _firebaseMessaging;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[NotificationService] Firebase no disponible: $e');
      return null;
    }
  }

  static Future<void> _initializeLocalNotifications(
    Function(String?)? onNotificationTapped,
  ) async {
    try {
      if (_localNotificationsInitialized) return;
      // Usar canal v2 para evitar caché de Android con canal de baja prioridad previo
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel_v2',
        'Auxilio Mecánico — Alertas',
        description: 'Alertas urgentes de auxilio mecánico con sonido y vibración',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
      if (kDebugMode) debugPrint("Canal creado: high_importance_channel_v2");
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode)
            debugPrint(
              '[NotificationService] Notificación tapped: ${response.payload}',
            );
          if (onNotificationTapped != null &&
              response.payload != null &&
              response.payload!.isNotEmpty) {
            onNotificationTapped(response.payload);
          }
        },
      );
      _localNotificationsInitialized = true;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[NotificationService] Error local notifications: $e');
    }
  }

  static void initializeNotifications(
    BuildContext context,
    Function(String?) onIncidentNotification,
  ) {
    try {
      if (_listenersInitialized) return;
      if (kDebugMode)
        debugPrint('[NotificationService] Inicializando listeners...');
      _initializeLocalNotifications((String? payload) {
        if (payload != null && payload.isNotEmpty) {
          // payload format: "ruta|incidenteId" o solo "incidenteId"
          String? ruta;
          String incidenteId = payload;
          if (payload.contains('|')) {
            final parts = payload.split('|');
            ruta = parts[0].isNotEmpty ? parts[0] : null;
            incidenteId = parts.length > 1 ? parts[1] : '';
          }
          if (incidenteId.isNotEmpty) {
            onIncidentNotification(incidenteId);
            if (ruta == '/tracking') {
              Navigator.of(context).pushNamed(
                '/tracking',
                arguments: {'incidente_id': incidenteId},
              );
            } else {
              Navigator.of(context).pushNamed(
                '/detalle-incidente',
                arguments: {'incidente_id': incidenteId},
              );
            }
          }
        }
      }).ignore();

      // Solicitar permisos (iOS) y ajustar opciones de presentación en primer plano
      requestPermission()
          .then((settings) {
            if (kDebugMode)
              debugPrint(
                '[NotificationService] Permisos: ${settings.authorizationStatus}',
              );
          })
          .catchError((e) {
            if (kDebugMode)
              debugPrint('[NotificationService] Error pidiendo permisos: $e');
          });

      try {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        if (kDebugMode)
          debugPrint(
            '[NotificationService] setForegroundNotificationPresentationOptions error: $e',
          );
      }
      final messaging = _messagingOrNull();
      if (messaging == null) return;
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(context, message, onIncidentNotification);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageOpenedApp(context, message, onIncidentNotification);
      });
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
            if (message != null) {
              _handleMessageOpenedApp(context, message, onIncidentNotification);
            }
          })
          .catchError((e) {
            if (kDebugMode)
              debugPrint('[NotificationService] getInitialMessage error: $e');
          });
      _listenersInitialized = true;
      if (kDebugMode) debugPrint('[NotificationService] Listeners registrados');
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] Error init: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      final messaging = _messagingOrNull();
      if (messaging == null) return null;
      final token = await messaging.getToken();
      if (kDebugMode) debugPrint('[NotificationService] Token: $token');
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] Error token: $e');
      return null;
    }
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('[NotificationService] Background: ${message.messageId}');
    try {
      // Inicializar local notifications en background también
      await _initializeLocalNotifications(null);

      // Extraer datos del mensaje
      final tipo =
          message.data['tipo'] ??
          message.data['titulo'] ??
          'Nueva notificación';
      final body =
          message.notification?.body ??
          message.data['message'] ??
          'Tienes una nueva notificación';

      if (kDebugMode)
        debugPrint(
          '[NotificationService] Background notification: title=$tipo, body=$body',
        );

      // Mostrar notificación local en background
      await _showBackgroundNotification(
        title: tipo,
        body: body,
        data: message.data,
      );
    } catch (e) {
      if (kDebugMode)
        debugPrint(
          '[NotificationService] Error handling background message: $e',
        );
    }
  }

  static Future<void> _showBackgroundNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel_v2',
        'Auxilio Mecánico — Alertas',
        channelDescription: 'Alertas urgentes de auxilio mecánico con sonido y vibración',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
      );
      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      // Incluir ruta en payload para navegación al tocar: "ruta|incidenteId"
      final incidenteId =
          (data['incidente_id'] ?? data['incidentId'] ?? '').toString();
      final ruta = (data['ruta'] ?? '').toString();
      final payloadStr = '${ruta}|${incidenteId}';
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        platformChannelSpecifics,
        payload: payloadStr,
      );
    } catch (e) {
      if (kDebugMode)
        debugPrint(
          '[NotificationService] Error showing background notification: $e',
        );
    }
  }

  static void _handleForegroundMessage(
    BuildContext context,
    RemoteMessage message,
    Function(String?) onIncidentNotification,
  ) {
    if (kDebugMode) {
      debugPrint("Notificación foreground recibida");
      debugPrint("Payload recibido: ${message.data}");
      debugPrint(
        '[NotificationService] Foreground message title=${message.notification?.title}',
      );
    }
    // Prefer to show incidente tipo (if present) to make the notification clearer
    final tipo = message.data['tipo'];
    final titleToShow = tipo != null && tipo.isNotEmpty
        ? tipo
        : (message.notification?.title ?? 'Nuevo aviso');
    final bodyToShow =
        message.notification?.body ?? (message.data['message'] ?? '');

    // Aceptar tanto incidente_id como incidentId
    final incidenteId =
        (message.data['incidente_id'] ?? message.data['incidentId'])
            ?.toString();
    // Leer ruta para decidir navegación
    final ruta = message.data['ruta']?.toString();

    // Incluir ruta en payload de la notificación local
    final payloadStr = '${ruta ?? ''}|${incidenteId ?? ''}';
    _showNotificationPopup(
      title: titleToShow,
      body: bodyToShow,
      payload: payloadStr,
    );

    if (incidenteId != null) {
      onIncidentNotification(incidenteId);
      // Navegar inmediatamente si la app está en primer plano
      if (ruta == '/tracking') {
        Navigator.of(context).pushNamed(
          '/tracking',
          arguments: {'incidente_id': incidenteId},
        );
      } else {
        Navigator.of(context).pushNamed(
          '/detalle-incidente',
          arguments: {'incidente_id': incidenteId},
        );
      }
    }
  }

  static Future<void> _showNotificationPopup({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (kDebugMode) debugPrint("Mostrando notificación local");
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel_v2',
        'Auxilio Mecánico — Alertas',
        channelDescription: 'Alertas urgentes de auxilio mecánico con sonido y vibración',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
      );
      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] Error show: $e');
    }
  }

  static void _handleMessageOpenedApp(
    BuildContext context,
    RemoteMessage message,
    Function(String?) onIncidentNotification,
  ) {
    final incidenteId =
        (message.data['incidente_id'] ?? message.data['incidentId'])
            ?.toString();
    final ruta = message.data['ruta']?.toString();
    if (incidenteId != null) {
      onIncidentNotification(incidenteId);
      if (ruta == '/tracking') {
        Navigator.of(context).pushNamed(
          '/tracking',
          arguments: {'incidente_id': incidenteId},
        );
      } else {
        Navigator.of(context).pushNamed(
          '/detalle-incidente',
          arguments: {'incidente_id': incidenteId},
        );
      }
    }
  }

  static Future<NotificationSettings> requestPermission() async {
    final messaging = _messagingOrNull();
    if (messaging == null) throw Exception('Firebase no disponible');
    return await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }
}
