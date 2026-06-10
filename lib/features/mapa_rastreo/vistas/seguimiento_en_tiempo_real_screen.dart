import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/incidentes/servicios/incidente_service.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';

/// Pantalla de tracking para que el empleado vea su ruta hacia el incidente
class EmployeeTrackingScreen extends StatefulWidget {
  final String incidenteId;
  
  const EmployeeTrackingScreen({
    super.key,
    required this.incidenteId,
  });

  @override
  State<EmployeeTrackingScreen> createState() => _EmployeeTrackingScreenState();
}

class _EmployeeTrackingScreenState extends State<EmployeeTrackingScreen> {
  late Future<Map<String, dynamic>> _trackingFuture;
  
  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  void _loadTracking() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _trackingFuture = IncidenteService(token: auth.token).obtenerTracking(widget.incidenteId);
  }

  void _refresh() {
    setState(() {
      _loadTracking();
    });
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
      appBar: AppBar(
        title: const Text('Mi Seguimiento'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _trackingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('No hay datos de seguimiento disponibles'),
            );
          }

          final tracking = snapshot.data!;
          return _buildTrackingContent(tracking);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildTrackingContent(Map<String, dynamic> tracking) {
    final incidenteLat = (tracking['latitud_incidente'] as num?)?.toDouble();
    final incidenteLon = (tracking['longitud_incidente'] as num?)?.toDouble();
    final tecnicoLat = (tracking['tecnico_latitud'] as num?)?.toDouble();
    final tecnicoLon = (tracking['tecnico_longitud'] as num?)?.toDouble();

    return Column(
      children: [
        // Mapa
        Expanded(
          flex: 3,
          child: _buildMap(incidenteLat, incidenteLon, tecnicoLat, tecnicoLon),
        ),
        
        // Información
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado del incidente
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.withOpacity(0.05),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Ubicación del Incidente',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Lat: ${incidenteLat?.toStringAsFixed(4) ?? "N/A"}'),
                        Text('Lon: ${incidenteLon?.toStringAsFixed(4) ?? "N/A"}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tu ubicación
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.withOpacity(0.05),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_pin_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tu Ubicación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Lat: ${tecnicoLat?.toStringAsFixed(4) ?? "N/A"}'),
                        Text('Lon: ${tecnicoLon?.toStringAsFixed(4) ?? "N/A"}'),
                        if (tracking['tecnico_ubicacion_actualizada_en'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Última actualización: ${tracking['tecnico_ubicacion_actualizada_en']}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Estado
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue.withOpacity(0.05),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(tracking['estado']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tracking['estado']?.toString().toUpperCase() ?? 'DESCONOCIDO',
                            style: TextStyle(
                              color: _getStatusColor(tracking['estado']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(
    double? incidenteLat,
    double? incidenteLon,
    double? tecnicoLat,
    double? tecnicoLon,
  ) {
    if (incidenteLat == null ||
        incidenteLon == null ||
        tecnicoLat == null ||
        tecnicoLon == null) {
      return Container(
        color: Colors.grey.withOpacity(0.1),
        child: const Center(
          child: Text('Ubicaciones no disponibles'),
        ),
      );
    }

    final incidentePoint = LatLng(incidenteLat, incidenteLon);
    final tecnicoPoint = LatLng(tecnicoLat, tecnicoLon);

    // Calcular el centro entre ambos puntos
    final centerLat = (incidenteLat + tecnicoLat!) / 2;
    final centerLon = (incidenteLon + tecnicoLon!) / 2;
    final centerPoint = LatLng(centerLat, centerLon);

    return FutureBuilder<List<LatLng>>(
      future: _getRoute(tecnicoLat, tecnicoLon, incidenteLat, incidenteLon),
      builder: (context, snapshot) {
        List<LatLng> routePoints = [tecnicoPoint, incidentePoint];
        
        if (snapshot.hasData) {
          routePoints = snapshot.data!;
        }

        return FlutterMap(
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'auxiliomecanico.app',
            ),
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
                // Marcador del incidente (rojo)
                Marker(
                  point: incidentePoint,
                  width: 50,
                  height: 50,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Incidente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),
                    ],
                  ),
                ),
                // Marcador del técnico (verde)
                Marker(
                  point: tecnicoPoint,
                  width: 50,
                  height: 50,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Yo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.person_pin_circle,
                        color: Colors.green,
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'en_proceso':
        return Colors.orange;
      case 'atendido':
        return Colors.green;
      case 'pendiente':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
