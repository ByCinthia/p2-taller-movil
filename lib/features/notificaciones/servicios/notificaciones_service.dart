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
      if (kDebugMode) debugPrint('[NotificationService] Firebase no disponible: $e');
      return null;
    }
  }

  static Future<void> _initializeLocalNotifications(Function(String?)? onNotificationTapped) async {
    try {
      if (_localNotificationsInitialized) return;
      const androidChannel = AndroidNotificationChannel('auxiliomecanico_channel', 'Auxilio Mecánico', description: 'Canal para notificaciones de auxilio mecánico', importance: Importance.max, enableVibration: true);
      await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) debugPrint('[NotificationService] Notificación tapped: ${response.payload}');
          if (onNotificationTapped != null && response.payload != null && response.payload!.isNotEmpty) {
            onNotificationTapped(response.payload);
          }
        },
      );
      _localNotificationsInitialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] Error local notifications: $e');
    }
  }

  static void initializeNotifications(BuildContext context, Function(String?) onIncidentNotification) {
    try {
      if (_listenersInitialized) return;
      if (kDebugMode) debugPrint('[NotificationService] Inicializando listeners...');
      _initializeLocalNotifications(onIncidentNotification).ignore();
      
      // Solicitar permisos (iOS) y ajustar opciones de presentación en primer plano
      requestPermission().then((settings) {
        if (kDebugMode) debugPrint('[NotificationService] Permisos: ${settings.authorizationStatus}');
      }).catchError((e) {
        if (kDebugMode) debugPrint('[NotificationService] Error pidiendo permisos: $e');
      });

      try {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      } catch (e) {
        if (kDebugMode) debugPrint('[NotificationService] setForegroundNotificationPresentationOptions error: $e');
      }
      final messaging = _messagingOrNull();
      if (messaging == null) return;
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(context, message, onIncidentNotification);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageOpenedApp(context, message, onIncidentNotification);
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
      final tipo = message.data['tipo'] ?? message.data['titulo'] ?? 'Nueva notificación';
      final body = message.notification?.body ?? message.data['message'] ?? 'Tienes una nueva notificación';
      
      if (kDebugMode) debugPrint('[NotificationService] Background notification: title=$tipo, body=$body');
      
      // Mostrar notificación local en background
      await _showBackgroundNotification(title: tipo, body: body, data: message.data);
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] Error handling background message: $e');
    }
  }

  static Future<void> _showBackgroundNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'auxiliomecanico_channel',
        'Auxilio Mecánico',
        channelDescription: 'Canal para notificaciones de auxilio mecánico',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );
      const platformChannelSpecifics = NotificationDetails(android: androidDetails);
      
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        platformChannelSpecifics,
        payload: data['incidente_id'] ?? '',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] Error showing background notification: $e');
    }
  }

  static void _handleForegroundMessage(BuildContext context, RemoteMessage message, Function(String?) onIncidentNotification) {
    if (kDebugMode) debugPrint('[NotificationService] Foreground message data=${message.data} title=${message.notification?.title}');
    // Prefer to show incidente tipo (if present) to make the notification clearer
    final tipo = message.data['tipo'];
    final titleToShow = tipo != null && tipo.isNotEmpty ? tipo : (message.notification?.title ?? 'Nuevo aviso');
    final bodyToShow = message.notification?.body ?? (message.data['message'] ?? '');
    _showNotificationPopup(title: titleToShow, body: bodyToShow);
    final incidentId = message.data['incidente_id'];
    if (incidentId != null) onIncidentNotification(incidentId);
  }

  static Future<void> _showNotificationPopup({required String title, required String body}) async {
    try {
      const androidDetails = AndroidNotificationDetails('auxiliomecanico_channel', 'Auxilio Mecánico', channelDescription: 'Canal para notificaciones de auxilio mecánico', importance: Importance.max, priority: Priority.high, playSound: true, enableVibration: true, enableLights: true);
      const platformChannelSpecifics = NotificationDetails(android: androidDetails);
      await _localNotifications.show(DateTime.now().millisecond, title, body, platformChannelSpecifics);
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] Error show: $e');
    }
  }

  static void _handleMessageOpenedApp(BuildContext context, RemoteMessage message, Function(String?) onIncidentNotification) {
    final incidentId = message.data['incidente_id'];
    if (incidentId != null) {
      onIncidentNotification(incidentId);
      Navigator.of(context).pushNamed('/detalle-incidente', arguments: {'incidentId': incidentId});
    }
  }

  static Future<NotificationSettings> requestPermission() async {
    final messaging = _messagingOrNull();
    if (messaging == null) throw Exception('Firebase no disponible');
    return await messaging.requestPermission(alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);
  }
}
