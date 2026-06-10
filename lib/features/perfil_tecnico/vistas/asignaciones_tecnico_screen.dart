import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/mapa_rastreo/estado/ubicacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';

class EmployeeAssignmentsScreen extends StatefulWidget {
  const EmployeeAssignmentsScreen({super.key});

  @override
  State<EmployeeAssignmentsScreen> createState() => _EmployeeAssignmentsScreenState();
}

class _EmployeeAssignmentsScreenState extends State<EmployeeAssignmentsScreen> {
  late Future<List<Map<String, dynamic>>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _loadAssignments() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token != null) {
      _assignmentsFuture = ApiService(token: token).getMyAsignaciones();
    } else {
      _assignmentsFuture = Future.value([]);
    }
  }

  Future<void> _refresh() async {
    setState(_loadAssignments);
    await _assignmentsFuture;
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de la app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Salir'),
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
    final pendingStatuses = {'pendiente', 'asignada', 'en_proceso', 'asignado', 'aceptada'};
    return items.where((item) {
      final status = (item['incidente_estado'] ?? '').toString().toLowerCase();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis asignaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

          final assignments = snapshot.data ?? [];
          final activeAssignments = _splitByStatus(assignments, false);
          final completedAssignments = _splitByStatus(assignments, true);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AssignmentsHeader(user: user),
                const SizedBox(height: 24),
                // Active assignments
                _AssignmentsSection(
                  title: 'Solicitudes activas',
                  subtitle: 'Pendientes, asignadas o en proceso',
                  count: activeAssignments.length,
                  assignments: activeAssignments,
                  isCompleted: false,
                  onRefresh: _refresh,
                ),
                const SizedBox(height: 24),
                // Completed assignments
                _AssignmentsSection(
                  title: 'Solicitudes completadas',
                  subtitle: 'Atendidas o finalizadas',
                  count: completedAssignments.length,
                  assignments: completedAssignments,
                  isCompleted: true,
                  onRefresh: _refresh,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AssignmentsHeader extends StatelessWidget {
  final User? user;

  const _AssignmentsHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis asignaciones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí ves solo las solicitudes que te asignaron',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final List<Map<String, dynamic>> assignments;
  final bool isCompleted;
  final Future<void> Function()? onRefresh;

  const _AssignmentsSection({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.assignments,
    required this.isCompleted,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey[300] : Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assignments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No hay solicitudes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            ),
          )
          else
          Column(
            children: assignments.map((assignment) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignment['incidente_tipo'] ?? 'Solicitud',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  assignment['incidente_descripcion'] ?? 'Sin descripción',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              assignment['incidente_estado'] ?? 'Desconocido',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DetailChip(
                            icon: Icons.info,
                            label: assignment['servicio_nombre'] ?? 'Sin servicio',
                          ),
                          _DetailChip(
                            icon: Icons.calendar_today,
                            label: assignment['fecha_asignacion'] ?? 'Sin fecha',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Mostrar botones según estado: si está en_proceso -> ver detalle + marcar atendida
                      // si no está en_proceso -> mostrar sólo "Comenzar tarea" (que abre el diálogo para iniciar)
                      Builder(
                        builder: (ctx) {
                          final status = (assignment['incidente_estado'] ?? '').toString().toLowerCase();
                          final maxW = MediaQuery.of(ctx).size.width;
                          final btnWidthFactor = maxW < 360 ? 0.9 : (maxW < 600 ? 0.46 : 0.32);

                          if (status == 'en_proceso') {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FractionallySizedBox(
                                      widthFactor: btnWidthFactor,
                                      child: ElevatedButton(
                                        onPressed: () => _openDetailDialog(context, assignment),
                                        child: const Text('Ver detalle'),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: btnWidthFactor,
                                      child: ElevatedButton(
                                        onPressed: () => _openDetailDialog(context, assignment, preselect: 'atendido'),
                                        child: const Text('Marcar atendida'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

                          // Si el estado es 'atendido' mostrar sólo Ver detalle (modo sólo lectura)
                          if (status == 'atendido') {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _openDetailDialog(context, assignment),
                                child: const Text('Ver detalle'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                              ),
                            );
                          }

                          // Estado distinto de en_proceso y distinto de atendido: mostrar sólo comenzar tarea
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _openDetailDialog(context, assignment, preselect: 'en_proceso'),
                              child: const Text('Comenzar tarea'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Helper to open detail dialog and allow changing estado
void _openDetailDialog(BuildContext context, Map<String, dynamic> assignment, {String? preselect}) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final token = auth.token;
  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No autorizado')));
    return;
  }

  showDialog<void>(
    context: context,
    builder: (context) {
      return FutureBuilder<Map<String, dynamic>>(
        future: ApiService(token: token).getIncidente((assignment['incidente_id'] ?? assignment['incidente'] ?? '').toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(content: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())));
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return AlertDialog(
              title: const Text('Detalle'),
              content: const Text('No se pudo cargar el detalle de la solicitud'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
            );
          }

          final detalle = snapshot.data!;
          String estadoSeleccionado = preselect ?? (detalle['estado'] ?? 'en_proceso').toString();

          return StatefulBuilder(
            builder: (context, setState) {
              final latController = TextEditingController();
              final lonController = TextEditingController();
              bool isProcessing = false;

              final bool isReadOnlyDetail = preselect == null && (detalle['estado'] ?? '').toString().toLowerCase() == 'atendido';

              return AlertDialog(
                title: const Text('Detalle de solicitud'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detalle['tipo'] ?? 'Solicitud', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(detalle['descripcion'] ?? 'Sin descripción'),
                      const SizedBox(height: 12),
                      Text('ID: ${detalle['id'] ?? ''}'),
                      const SizedBox(height: 6),
                      Text('Estado actual: ${detalle['estado'] ?? ''}'),
                      const SizedBox(height: 6),
                      Text('Vehículo: ${detalle['vehiculo_id'] ?? 'N/A'}'),
                      const SizedBox(height: 6),
                      Text('Prioridad: ${detalle['prioridad'] ?? 'N/A'}'),
                      const SizedBox(height: 6),
                      Text('Ubicación incidente: ${detalle['latitud'] ?? 'N/A'}, ${detalle['longitud'] ?? 'N/A'}'),
                      const SizedBox(height: 12),
                      // Mostrar controles de cambio sólo si este diálogo fue invocado para cambiar estado (preselect != null)
                      if (preselect != null) ...[
                        const Text('Cambiar estado'),
                        DropdownButton<String>(
                          value: estadoSeleccionado,
                          items: const [
                            DropdownMenuItem(value: 'en_proceso', child: Text('En proceso')),
                            DropdownMenuItem(value: 'atendido', child: Text('Atendido')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => estadoSeleccionado = v);
                          },
                        ),
                        // Si está en "en_proceso", mostrar inputs para lat/lon
                        if (estadoSeleccionado == 'en_proceso') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tu Ubicación (para pruebas)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: latController,
                                  decoration: InputDecoration(
                                    labelText: 'Latitud (o dejar vacío)',
                                    hintText: 'Ej: 10.5234',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    isDense: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: lonController,
                                  decoration: InputDecoration(
                                    labelText: 'Longitud (o dejar vacío)',
                                    hintText: 'Ej: -66.4321',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    isDense: true,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                ),
                                const SizedBox(height: 8),
                                const Text('Si dejas vacío, se usará tu ubicación GPS', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ],
                      // Si el estado actual es "en_proceso", mostrar botón para ver seguimiento
                      if ((detalle['estado'] ?? '').toString().toLowerCase() == 'en_proceso') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                '/empleado/tracking',
                                arguments: detalle['id'].toString(),
                              );
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('Ver Mi Seguimiento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: isReadOnlyDetail
                    ? []
                    : [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                        if (preselect != null)
                          ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    try {
                                      setState(() => isProcessing = true);
                                      double? latitud, longitud;

                                      if (estadoSeleccionado == 'en_proceso') {
                                        if (latController.text.isNotEmpty && lonController.text.isNotEmpty) {
                                          try {
                                            latitud = double.parse(latController.text);
                                            longitud = double.parse(lonController.text);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Usando ubicación manual')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Valores de ubicación inválidos')),
                                            );
                                            setState(() => isProcessing = false);
                                            return;
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Obteniendo tu ubicación GPS...')),
                                          );
                                          final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                                          final position = await locationProvider.getCurrentLocation();
                                          if (position != null) {
                                            latitud = position.latitude;
                                            longitud = position.longitude;
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('No se pudo obtener ubicación')),
                                            );
                                            setState(() => isProcessing = false);
                                            return;
                                          }
                                        }
                                      }

                                      await ApiService(token: token).updateIncidenteEstado(
                                        detalle['id'].toString(),
                                        estadoSeleccionado,
                                        latitud: latitud,
                                        longitud: longitud,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Estado actualizado')),
                                      );

                                      if (estadoSeleccionado == 'en_proceso') {
                                        setState(() => isProcessing = false);
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('¡Excelente!'),
                                            content: const Text(
                                              'Tu ubicación ha sido enviada. ¿Deseas ver el mapa de seguimiento?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  Navigator.pop(context);
                                                  if (context.findAncestorStateOfType<_EmployeeAssignmentsScreenState>() != null) {
                                                    context.findAncestorStateOfType<_EmployeeAssignmentsScreenState>()!._refresh();
                                                  }
                                                },
                                                child: const Text('Después'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  Navigator.pop(context);
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/empleado/tracking',
                                                    arguments: detalle['id'].toString(),
                                                  );
                                                },
                                                child: const Text('Ver Seguimiento'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      setState(() => isProcessing = false);
                                      Navigator.pop(context);
                                      if (context.findAncestorStateOfType<_EmployeeAssignmentsScreenState>() != null) {
                                        context.findAncestorStateOfType<_EmployeeAssignmentsScreenState>()!._refresh();
                                      }
                                    } catch (e) {
                                      setState(() => isProcessing = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                            child: Text(
                              estadoSeleccionado == 'en_proceso'
                                  ? 'Enviar ubicación actual'
                                  : (estadoSeleccionado == 'atendido' ? 'Marcar atendida' : 'Guardar'),
                            ),
                          ),
                      ],
              );
            },
          );
        },
      );
    },
  );
}
