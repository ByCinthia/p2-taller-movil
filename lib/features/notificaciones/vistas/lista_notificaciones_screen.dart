import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/notificaciones/vistas/detalle_notificacion_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token != null) {
      _notificationsFuture = ApiService(token: token).getMyNotifications();
    } else {
      _notificationsFuture = Future.value(const <Map<String, dynamic>>[]);
    }
  }

  Future<void> _refresh() async {
    setState(_loadNotifications);
    await _notificationsFuture;
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationDetailScreen(
            notification: notification,
          ),
        ),
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
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones${auth.userRole != null ? ' (${auth.userRole})' : ''}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'No se pudieron cargar las notificaciones',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? const <Map<String, dynamic>>[];
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No tienes notificaciones todavía')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['leida'] == true;
                return Card(
                  elevation: isRead ? 1 : 3,
                  child: ListTile(
                    onTap: () => _openNotification(notification),
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey.shade300 : Theme.of(context).colorScheme.primary,
                      child: Icon(
                        isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: isRead ? Colors.black54 : Colors.white,
                      ),
                    ),
                    title: Text(
                      notification['titulo']?.toString() ?? 'Notificación',
                      style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification['mensaje']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(notification['creada_en']),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: isRead
                        ? const Icon(Icons.done_all, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
