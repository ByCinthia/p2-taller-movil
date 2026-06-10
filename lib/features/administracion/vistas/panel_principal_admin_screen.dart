import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/incidentes/servicios/incidente_service.dart';
import 'package:auxiliomecanico_movil/features/perfil_tecnico/modelos/asignacion_empleado.dart';
import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/barra_superior_personalizada.dart';

/// Pantalla principal del administrador: perfil + solicitudes.
class AdminHomeScreen extends StatefulWidget {
  final int initialTab;

  const AdminHomeScreen({super.key, this.initialTab = 0});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Future<List<Map<String, dynamic>>>? _incidentsFuture;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  void _loadIncidents() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token != null) {
      _incidentsFuture = IncidenteService(token: token).listarIncidentes();
    }
  }

  Future<void> _refresh() async {
    setState(_loadIncidents);
    await _incidentsFuture;
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _splitByStatus(
    List<Map<String, dynamic>> items,
    bool attended,
  ) {
    final attendedStatuses = {'atendido', 'cerrado', 'finalizado', 'completado'};
    final pendingStatuses = {'pendiente', 'en_proceso', 'asignado', 'aceptada'};
    return items.where((item) {
      final status = (item['estado'] ?? '').toString().toLowerCase();
      if (attended) {
        return attendedStatuses.contains(status);
      }
      return pendingStatuses.contains(status) || status.isEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (_incidentsFuture == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _incidentsFuture == null) {
          setState(_loadIncidents);
        }
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Panel Administrador',
        user: user,
        onLogout: () => _logout(context),
      ),
      body: DefaultTabController(
        length: 2,
        initialIndex: widget.initialTab,
        child: Column(
          children: [
            const Material(
              color: Colors.white,
              child: TabBar(
                tabs: [
                  Tab(text: 'Perfil'),
                  Tab(text: 'Solicitudes'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AdminProfileSummary(user: user, initial: _initialFrom(user)),
                  _AdminRequestsView(
                    incidentsFuture: _incidentsFuture,
                    onRefresh: _refresh,
                    splitByStatus: _splitByStatus,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initialFrom(User? user) {
    final fullName = user?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName[0].toUpperCase();
    }
    final username = user?.username.trim() ?? '';
    if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }
    return '?';
  }
}

class _AdminProfileSummary extends StatelessWidget {
  final User? user;
  final String initial;

  const _AdminProfileSummary({required this.user, required this.initial});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileHeader(
          title: 'Panel Administrador',
          subtitle: 'Perfil del taller',
          user: user,
          initial: initial,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Datos del administrador', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _InfoRow(label: 'Usuario', value: user?.username ?? 'N/A'),
                _InfoRow(label: 'Correo', value: user?.email ?? 'N/A'),
                _InfoRow(label: 'Nombre', value: user?.fullName),
                _InfoRow(label: 'Rol', value: user?.role.toUpperCase() ?? 'N/A'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Mis notificaciones'),
            subtitle: const Text('Ver avisos y solicitudes recientes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/notificaciones'),
          ),
        ),
      ],
    );
  }
}

class _AdminRequestsView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>>? incidentsFuture;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>> Function(List<Map<String, dynamic>>, bool) splitByStatus;

  const _AdminRequestsView({
    required this.incidentsFuture,
    required this.onRefresh,
    required this.splitByStatus,
  });

  @override
  State<_AdminRequestsView> createState() => _AdminRequestsViewState();
}

class _AdminRequestsViewState extends State<_AdminRequestsView> {
  late final ApiService _api;
  Future<List<Map<String, dynamic>>>? _servicesFuture;
  Future<List<EmployeeAssignment>>? _employeesFuture;

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _api = ApiService(token: token);
    _loadReferences();
  }

  void _loadReferences() {
    _servicesFuture = _api.getServicios();
    _employeesFuture = _api.getAssignableEmployees();
  }

  String _statusLabel(String? status) {
    final value = (status ?? 'pendiente').toLowerCase();
    switch (value) {
      case 'atendido':
      case 'cerrado':
      case 'finalizado':
      case 'completado':
        return 'Atendida';
      case 'en_proceso':
        return 'En proceso';
      case 'asignado':
        return 'Asignada';
      default:
        return 'Pendiente';
    }
  }

  Color _statusColor(String? status) {
    final value = (status ?? 'pendiente').toLowerCase();
    switch (value) {
      case 'atendido':
      case 'cerrado':
      case 'finalizado':
      case 'completado':
        return Colors.green;
      case 'en_proceso':
        return Colors.orange;
      case 'asignado':
        return Colors.blue;
      default:
        return Colors.redAccent;
    }
  }

  Future<void> _openAssignmentSheet(Map<String, dynamic> incident) async {
    if (_servicesFuture == null || _employeesFuture == null) {
      _loadReferences();
    }

    final services = await (_servicesFuture ?? Future.value(const <Map<String, dynamic>>[]));
    final employees = await (_employeesFuture ?? Future.value(const <EmployeeAssignment>[]));
    if (!mounted) return;

    if (services.isEmpty || employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay servicios o empleados disponibles para asignar')),
      );
      return;
    }

    String? selectedServiceId = services.first['id_servicio']?.toString();
    String? selectedEmployeeId = employees.first.id;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Asignar solicitud', style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(incident['tipo']?.toString() ?? 'Solicitud', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedServiceId,
                    decoration: const InputDecoration(labelText: 'Servicio'),
                    items: services
                        .map(
                          (service) => DropdownMenuItem<String>(
                            value: service['id_servicio']?.toString(),
                            child: Text(service['nombre']?.toString() ?? 'Servicio'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setSheetState(() => selectedServiceId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedEmployeeId,
                    decoration: const InputDecoration(labelText: 'Empleado'),
                    items: employees
                        .map(
                          (employee) => DropdownMenuItem<String>(
                            value: employee.id,
                            child: Text(employee.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setSheetState(() => selectedEmployeeId = value),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedServiceId == null || selectedEmployeeId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selecciona servicio y empleado')),
                        );
                        return;
                      }

                      try {
                        await _api.assignTecnico(incident['id']?.toString() ?? '', {
                          'empleado_id': selectedEmployeeId,
                          'servicio_id': selectedServiceId,
                        });

                        if (!mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Solicitud asignada correctamente')),
                        );
                        await widget.onRefresh();
                        if (mounted) setState(() {});
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al asignar: $e')),
                        );
                      }
                    },
                    child: const Text('Asignar solicitud'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.incidentsFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.incidentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error cargando solicitudes: ${snapshot.error}'),
                  ),
                ),
              ],
            );
          }

          final items = snapshot.data ?? [];
          final pending = widget.splitByStatus(items, false);
          final attended = widget.splitByStatus(items, true);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _IncidentSection(
                title: 'Solicitudes nuevas',
                count: pending.length,
                children: pending
                    .map(
                      (item) => _IncidentCard(
                        item: item,
                        statusLabel: _statusLabel(item['estado']?.toString()),
                        statusColor: _statusColor(item['estado']?.toString()),
                        onAssign: () => _openAssignmentSheet(item),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _IncidentSection(
                title: 'Solicitudes atendidas',
                count: attended.length,
                children: attended
                    .map(
                      (item) => _IncidentCard(
                        item: item,
                        statusLabel: _statusLabel(item['estado']?.toString()),
                        statusColor: _statusColor(item['estado']?.toString()),
                        onAssign: null,
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IncidentSection extends StatelessWidget {
  final String title;
  final int count;
  final List<Widget> children;

  const _IncidentSection({required this.title, required this.count, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text('$count'),
              ],
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              const Text('No hay solicitudes en esta categoría')
            else
              Column(children: children),
          ],
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onAssign;

  const _IncidentCard({
    required this.item,
    required this.statusLabel,
    required this.statusColor,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final id = item['id']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['tipo']?.toString() ?? 'Solicitud',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item['descripcion']?.toString() ?? 'Sin descripción',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('Vehículo: ${item['vehiculo_id'] ?? 'N/A'}'),
                Text('Prioridad: ${item['prioridad'] ?? '-'}'),
                Text('Lat: ${item['latitud'] ?? '-'}'),
                Text('Lon: ${item['longitud'] ?? '-'}'),
                Text('Fecha: ${item['creado_en'] ?? '-'}'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/tracking', arguments: {'incidente_id': id});
                  },
                  child: const Text('Ver seguimiento'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/detalle-incidente', arguments: {'incidente_id': id});
                  },
                  child: const Text('Ver detalle'),
                ),
                if (onAssign != null)
                  ElevatedButton(
                    onPressed: onAssign,
                    child: const Text('Asignar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final User? user;
  final String initial;

  const _ProfileHeader({
    required this.title,
    required this.subtitle,
    required this.user,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    user?.fullName ?? user?.username ?? 'Usuario',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : 'N/A')),
        ],
      ),
    );
  }
}