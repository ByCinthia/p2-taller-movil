import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';

class NotificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late Map<String, dynamic> _notification;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (_notification['leida'] == true) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    try {
      await ApiService(
        token: token,
      ).markNotificationAsRead(_notification['id'].toString());
      setState(() {
        _notification['leida'] = true;
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _navigateToIncident() async {
    final data =
        (_notification['data'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final incidentId = data['incidente_id']?.toString();

    if (incidentId == null || incidentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta notificación no está asociada a un incidente'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/detalle-incidente',
        arguments: {'incidente_id': incidentId},
      );
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Sin fecha';
    }
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return value.toString();
    }
    return _dateFormat.format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final data =
        (_notification['data'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final isRead = _notification['leida'] == true;
    final hasIncident =
        data['incidente_id'] != null &&
        data['incidente_id'].toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de notificación'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRead ? Icons.done_all : Icons.notifications_active,
                        size: 16,
                        color: isRead
                            ? Colors.grey.shade600
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRead ? 'Leída' : 'No leída',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isRead
                              ? Colors.grey.shade600
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Título
            Text('Título', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _notification['titulo']?.toString() ?? 'Sin título',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mensaje
            Text('Mensaje', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _notification['mensaje']?.toString() ?? 'Sin mensaje',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fecha
            Text('Fecha', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(_notification['creada_en']),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tipo de notificación
            if (data['tipo'] != null && data['tipo'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de notificación',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        data['tipo']?.toString() ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Actor (quien realizó la acción)
            if (data['actor_nombre'] != null &&
                data['actor_nombre'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Realizado por',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['actor_nombre']?.toString() ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Incident ID
            if (hasIncident)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solicitud asociada',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Solicitud #${data['incidente_id']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Additional data if any
            if (data.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información adicional',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Campo')),
                            DataColumn(label: Text('Valor')),
                          ],
                          rows: data.entries
                              .where(
                                (e) =>
                                    e.key != 'incidente_id' &&
                                    e.key != 'actor_nombre' &&
                                    e.key != 'tipo' &&
                                    e.key != 'titulo',
                              )
                              .map(
                                (e) => DataRow(
                                  cells: [
                                    DataCell(Text(e.key)),
                                    DataCell(Text(e.value?.toString() ?? '-')),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Button to go to incident
            if (hasIncident)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _navigateToIncident,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.open_in_new),
                  label: const Text('Ver solicitud'),
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
