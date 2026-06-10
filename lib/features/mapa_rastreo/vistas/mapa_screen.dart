import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/incidentes/servicios/incidente_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String? incidenteId;
  bool loading = true;
  String? error;
  Map<String, dynamic>? tracking;
  List<Map<String, dynamic>> tecnicos = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    incidenteId = args != null ? args['incidente_id']?.toString() : null;
    _load();
  }

  Future<void> _load() async {
    if (incidenteId == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final svc = IncidenteService(token: token);
    try {
      final t = await svc.obtenerTracking(incidenteId!);
      setState(() {
        tracking = t;
      });

      final lat = (t['latitud_incidente'] as num?)?.toDouble();
      final lon = (t['longitud_incidente'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        final list = await svc.listarTecnicosCercanos(lat, lon);
        setState(() {
          tecnicos = list;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  int _stateIndexFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'pendiente':
        return 0;
      case 'asignado':
        return 1;
      case 'en_proceso':
      case 'en proceso':
        return 2;
      case 'atendido':
        return 3;
      case 'cancelado':
        return 4;
      default:
        return 0;
    }
  }

  /// Obtiene la ruta real desde OSRM (Open Source Routing Machine)
  Future<List<LatLng>> _getRoute(double startLat, double startLon, double endLat, double endLon) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat'
          '?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['routes'] != null && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final geometry = route['geometry'];
          
          if (geometry != null && geometry['coordinates'] != null) {
            final List<LatLng> routePoints = [];
            for (var coord in geometry['coordinates']) {
              routePoints.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
            }
            return routePoints;
          }
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo ruta: $e');
    }
    
    // Fallback a línea recta si falla OSRM
    return [LatLng(startLat, startLon), LatLng(endLat, endLon)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento del incidente')),
      drawer: const AppDrawer(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // MAPA
                      _buildMap(),
                      const SizedBox(height: 16),

                      // INFORMACIÓN
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Incidente: ${incidenteId ?? '-'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (tracking != null) ...[
                                      Text(
                                        'Estado: ${tracking!['estado'] ?? '-'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Stepper(
                                        currentStep: _stateIndexFromString(
                                          tracking!['estado']?.toString(),
                                        ),
                                        steps: const [
                                          Step(
                                            title: Text('Pendiente'),
                                            content: SizedBox.shrink(),
                                          ),
                                          Step(
                                            title: Text('Asignado'),
                                            content: SizedBox.shrink(),
                                          ),
                                          Step(
                                            title: Text('En proceso'),
                                            content: SizedBox.shrink(),
                                          ),
                                          Step(
                                            title: Text('Atendido'),
                                            content: SizedBox.shrink(),
                                          ),
                                          Step(
                                            title: Text('Cancelado'),
                                            content: SizedBox.shrink(),
                                          ),
                                        ],
                                        controlsBuilder: (_, __) =>
                                            const SizedBox.shrink(),
                                      ),
                                      const SizedBox(height: 12),
                                      if (tracking!['empleado_id'] != null) ...[
                                        Text(
                                          'Técnico asignado: ${tracking!['tecnico_nombre'] ?? '-'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Última actualización: ${tracking!['tecnico_ubicacion_actualizada_en'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar seguimiento'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // TÉCNICOS CERCANOS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Técnicos / talleres cercanos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (tecnicos.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'No hay técnicos disponibles cerca de tu ubicación',
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: tecnicos.length,
                                itemBuilder: (context, i) {
                                  final t = tecnicos[i];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(
                                        t['nombre_completo'] ?? 'Técnico cercano',
                                      ),
                                      subtitle: Text(
                                        '${t['empresa_nombre'] ?? ''} • Dist: ${t['distancia_km'] ?? '-'} km',
                                      ),
                                      trailing: t['disponible'] == true
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                          : const Icon(
                                              Icons.remove_circle,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMap() {
    final incidenteLat =
        (tracking?['latitud_incidente'] as num?)?.toDouble();
    final incidenteLon =
        (tracking?['longitud_incidente'] as num?)?.toDouble();
    final tecnicoLat = (tracking?['tecnico_latitud'] as num?)?.toDouble();
    final tecnicoLon = (tracking?['tecnico_longitud'] as num?)?.toDouble();

    if (incidenteLat == null || incidenteLon == null) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Text('Ubicación del incidente no disponible'),
        ),
      );
    }

    final incidentePoint = LatLng(incidenteLat, incidenteLon);
    final tecnicoPoint =
        tecnicoLat != null && tecnicoLon != null ? LatLng(tecnicoLat, tecnicoLon) : null;

    // Calcular bounds para centrar el mapa
    double centerLat, centerLon;
    if (tecnicoPoint != null) {
      centerLat = (incidenteLat + tecnicoLat!) / 2;
      centerLon = (incidenteLon + tecnicoLon!) / 2;
    } else {
      centerLat = incidenteLat;
      centerLon = incidenteLon;
    }

    return SizedBox(
      height: 300,
      child: FutureBuilder<List<LatLng>>(
        future: tecnicoPoint != null 
            ? _getRoute(tecnicoLat!, tecnicoLon!, incidenteLat, incidenteLon)
            : Future.value([incidentePoint]),
        builder: (context, snapshot) {
          List<LatLng> routePoints = tecnicoPoint != null
              ? [incidentePoint, tecnicoPoint]
              : [incidentePoint];

          if (snapshot.hasData) {
            routePoints = snapshot.data!;
          }

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLon),
              initialZoom: tecnicoPoint != null ? 12 : 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.auxiliomecanico',
              ),
              if (tecnicoPoint != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blue,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Marker para el incidente
                  Marker(
                    point: incidentePoint,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Incidente',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                  // Marker para el técnico (si está disponible)
                  if (tecnicoPoint != null)
                    Marker(
                      point: tecnicoPoint,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Técnico',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
