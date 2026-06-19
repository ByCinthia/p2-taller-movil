import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/incidentes/servicios/incidente_service.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _loadIncidentes();
  }

  void _loadIncidentes() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final svc = IncidenteService(token: token);
    _future = svc.listarIncidentes();
  }

  bool _esEstadoFinal(String? estado) {
    if (estado == null) return false;
    final s = estado.toLowerCase();
    return ['atendido', 'atendida', 'finalizado', 'finalizada',
            'completado', 'completada', 'cancelado', 'cancelada'].contains(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de incidentes')),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay incidentes registrados'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final inc = items[index];
              final id = inc['id']?.toString() ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inc['tipo']?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(inc['descripcion']?.toString() ?? ''),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        children: [
                          Text('Estado: ${inc['estado'] ?? '-'}'),
                          Text('Prioridad: ${inc['prioridad'] ?? '-'}'),
                          Text('Lat: ${inc['latitud'] ?? '-'}'),
                          Text('Lon: ${inc['longitud'] ?? '-'}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final btnWidthFactor = maxW < 360 ? 0.48 : (maxW < 600 ? 0.47 : 0.32);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  // Mostrar seguimiento solo si no está finalizado
                                  if (!_esEstadoFinal(inc['estado']?.toString()))
                                    FractionallySizedBox(
                                      widthFactor: btnWidthFactor,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/cliente/seguimiento',
                                            arguments: id,
                                          );
                                        },
                                        icon: const Icon(Icons.location_on, size: 16),
                                        label: const Text('Seguimiento'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6C63FF),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  FractionallySizedBox(
                                    widthFactor: btnWidthFactor,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/detalle-incidente',
                                          arguments: {'incidente_id': id},
                                        );
                                      },
                                      child: const Text('Ver detalle'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FractionallySizedBox(
                                widthFactor: 1.0,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      '/agregar-evidencia',
                                      arguments: {'incidente_id': id},
                                    );
                                    // refrescar lista
                                    setState(() => _loadIncidentes());
                                  },
                                  child: const Text('Agregar evidencia'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
