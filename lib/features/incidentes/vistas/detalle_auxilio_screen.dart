import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/incidentes/servicios/incidente_service.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';

class DetalleIncidenteScreen extends StatefulWidget {
  const DetalleIncidenteScreen({super.key});

  @override
  State<DetalleIncidenteScreen> createState() => _DetalleIncidenteScreenState();
}

class _DetalleIncidenteScreenState extends State<DetalleIncidenteScreen> {
  String? incidenteId;
  bool loading = true;
  String? error;
  Map<String, dynamic>? incidente;

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
      final res = await svc.obtenerIncidente(incidenteId!);
      setState(() {
        incidente = res;
      });
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

  void _showEvidencias() {
    if (incidenteId == null) return;
    showDialog(
      context: context,
      builder: (context) => _EvidenciasDialog(incidenteId: incidenteId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del incidente')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text('Error: $error'))
                : incidente == null
                    ? const Center(child: Text('Incidente no encontrado'))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            incidente!['tipo']?.toString() ?? 'Solicitud',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(incidente!['estado']),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            incidente!['estado']?.toString() ?? 'Desconocido',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      incidente!['descripcion']?.toString() ?? 'Sin descripción',
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Información General
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Información General',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoRow(
                                      label: 'ID',
                                      value: incidente!['id']?.toString() ?? '-',
                                    ),
                                    _InfoRow(
                                      label: 'Prioridad',
                                      value: 'P${incidente!['prioridad']?.toString() ?? '-'}',
                                    ),
                                    _InfoRow(
                                      label: 'Vehículo',
                                      value: incidente!['vehiculo_id']?.toString() ?? 'N/A',
                                    ),
                                    _InfoRow(
                                      label: 'Ubicación',
                                      value:
                                          '${incidente!['latitud']?.toString() ?? '-'}, ${incidente!['longitud']?.toString() ?? '-'}',
                                    ),
                                    _InfoRow(
                                      label: 'Fecha',
                                      value: incidente!['creado_en']?.toString() ?? '-',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Botón Ver Evidencias
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showEvidencias,
                                icon: const Icon(Icons.image),
                                label: const Text('Ver Evidencias'),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Color _getStatusColor(dynamic estado) {
    final estStr = estado?.toString().toLowerCase() ?? '';
    if (estStr.contains('pendiente')) return Colors.orange;
    if (estStr.contains('proceso')) return Colors.blue;
    if (estStr.contains('atendido') || estStr.contains('finalizado')) return Colors.green;
    return Colors.grey;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenciasDialog extends StatefulWidget {
  final String incidenteId;

  const _EvidenciasDialog({required this.incidenteId});

  @override
  State<_EvidenciasDialog> createState() => _EvidenciasDialogState();
}

class _EvidenciasDialogState extends State<_EvidenciasDialog> {
  late Future<List<Map<String, dynamic>>> _evidenciasFuture;

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final svc = IncidenteService(token: token);
    _evidenciasFuture = svc.obtenerEvidencias(widget.incidenteId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _evidenciasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: 200,
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          final evidencias = snapshot.data ?? [];

          if (evidencias.isEmpty) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No hay evidencias registradas'),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evidencias del incidente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: evidencias.length,
                    itemBuilder: (context, index) {
                      final ev = evidencias[index];
                      final tipo = ev['tipo']?.toString() ?? 'unknown';
                      final url = ev['url_archivo']?.toString();
                      final texto = ev['texto']?.toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tipo: $tipo',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                if (url != null && url.isNotEmpty) ...[
                                  Image.network(
                                    url,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.broken_image, size: 64),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ] else if (texto != null && texto.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(texto),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Sin contenido'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
