import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:auxiliomecanico_movil/firebase_options.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/mapa_rastreo/estado/ubicacion_proveedor.dart';
import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/vistas/iniciar_sesion_screen.dart';
import 'package:auxiliomecanico_movil/features/administracion/vistas/panel_principal_admin_screen.dart';
import 'package:auxiliomecanico_movil/features/administracion/vistas/perfil_admin_screen.dart';
import 'package:auxiliomecanico_movil/features/administracion/vistas/lista_empleados_screen.dart';
import 'package:auxiliomecanico_movil/features/clientes/vistas/perfil_cliente_screen.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/vistas/lista_vehiculos_screen.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/vistas/registrar_vehiculo_screen.dart';
import 'package:auxiliomecanico_movil/features/incidentes/vistas/solicitar_auxilio_screen.dart';
import 'package:auxiliomecanico_movil/features/incidentes/vistas/historial_auxilios_screen.dart';
import 'package:auxiliomecanico_movil/features/mapa_rastreo/vistas/mapa_screen.dart';
import 'package:auxiliomecanico_movil/features/incidentes/vistas/agregar_evidencia_screen.dart';
import 'package:auxiliomecanico_movil/features/incidentes/vistas/detalle_auxilio_screen.dart';
import 'package:auxiliomecanico_movil/features/mapa_rastreo/vistas/seleccionar_ubicacion_screen.dart';
import 'package:auxiliomecanico_movil/features/perfil_tecnico/vistas/panel_principal_tecnico_screen.dart';
import 'package:auxiliomecanico_movil/features/perfil_tecnico/vistas/perfil_usuario_screen.dart';
import 'package:auxiliomecanico_movil/features/perfil_tecnico/vistas/asignaciones_tecnico_screen.dart';
import 'package:auxiliomecanico_movil/features/mapa_rastreo/vistas/seguimiento_en_tiempo_real_screen.dart';
import 'package:auxiliomecanico_movil/features/notificaciones/vistas/lista_notificaciones_screen.dart';
import 'package:auxiliomecanico_movil/core/tema/tema_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/notificaciones/servicios/notificaciones_service.dart';

/// Manejador de mensajes en background (DEBE ser función de nivel superior)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.handleBackgroundMessage(message);
  } catch (e) {
    debugPrint('Firebase no disponible en background: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capturar excepciones que ocurran fuera de la zona Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ FLUTTER ERROR: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  try {
    debugPrint('🔥 Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase inicializado');

    //imprimri en la consola el fcm token para pruebas
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('🔑 FCM Token: $fcmToken');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background message handler registrado');
  } catch (e) {
    debugPrint('⚠️ No se pudo inicializar Firebase en main: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, LocationProvider>(
          create: (_) => LocationProvider(apiService: ApiService()),
          update: (_, authProvider, locationProvider) {
            // Actualizar el token en LocationProvider si es necesario
            return locationProvider ??
                LocationProvider(
                  apiService: ApiService(token: authProvider.token),
                );
          },
        ),
      ],
      child: MaterialApp(
        title: 'Auxilio Mecánico',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthCheck(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/perfil': (context) => const ProfileEntryScreen(),
          '/profile': (context) => const ProfileEntryScreen(),
          '/admin/panel': (context) => const AdminHomeScreen(initialTab: 1),
          '/admin/empleados': (context) => const ListaEmpleadosScreen(),
          '/vehiculos': (context) => const VehiclesListScreen(),
          '/registrar-vehiculo': (context) => const VehicleRegisterScreen(),
          '/registrar-incidente': (context) => const IncidentReportScreen(),
          '/solicitud-auxilio': (context) => const IncidentReportScreen(),
          '/agregar-evidencia': (context) => const AgregarEvidenciaScreen(),
          '/seleccionar-ubicacion': (context) =>
              const SeleccionarUbicacionScreen(),
          '/historial-incidentes': (context) => const IncidentHistoryScreen(),
          '/tracking': (context) => const TrackingScreen(),
          '/detalle-incidente': (context) => const DetalleIncidenteScreen(),
          '/empleado/perfil': (context) => const EmployeeProfileScreen(),
          '/empleado/home': (context) => const EmployeeHomeScreen(),
          '/empleado/asignaciones': (context) {
            final tipoFiltro = ModalRoute.of(context)?.settings.arguments as String? ?? 'asignadas';
            return AsignacionesEmpleadoScreen(tipoFiltro: tipoFiltro);
          },
          '/empleado/tracking': (context) {
            final incidenteId =
                ModalRoute.of(context)?.settings.arguments as String?;
            if (incidenteId == null) {
              return const Scaffold(
                body: Center(child: Text('ID de incidente no proporcionado')),
              );
            }
            return EmployeeTrackingScreen(incidenteId: incidenteId);
          },
          '/notificaciones': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}

class ProfileEntryScreen extends StatelessWidget {
  const ProfileEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.userRole == 'admin') {
      return const AdminProfileScreen();
    }
    if (authProvider.userRole == 'empleado') {
      return const EmployeeProfileScreen();
    }
    return const ProfileScreen();
  }
}

/// Widget que verifica el estado de autenticación y redirige a la pantalla correspondiente
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    // Inicializar listeners de notificaciones después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        authProvider.initializeNotificationListeners(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context);

      if (authProvider.isLoading) {
        debugPrint('⏳ AuthCheck: Usuario cargando...');
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (!authProvider.isAuthenticated) {
        debugPrint('🔓 AuthCheck: Usuario no autenticado -> LoginScreen');
        return const LoginScreen();
      }

      // Inicializar listeners cuando se autentica
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          authProvider.initializeNotificationListeners(context);
        } catch (e) {
          debugPrint('⚠️ Error inicializando notification listeners: $e');
        }
      });

      // Redirige directamente al perfil correspondiente según el rol.
      final userRole = authProvider.userRole;
      debugPrint('🔀 ROUTING: Rol del usuario = $userRole');

      if (userRole == 'admin') {
        debugPrint('🔀 -> Dirigiendo a AdminProfileScreen');
        return const AdminProfileScreen();
      }

      if (userRole == 'cliente') {
        debugPrint('🔀 -> Dirigiendo a ProfileScreen');
        return const ProfileScreen();
      }

      if (userRole == 'empleado') {
        debugPrint('🔀 -> Dirigiendo a EmployeeProfileScreen');
        return const EmployeeProfileScreen();
      }

      debugPrint(
        '🔀 -> Rol desconocido: "$userRole", dirigiendo a LoginScreen',
      );
      return const LoginScreen();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR EN AuthCheck.build(): $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Error Crítico',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
