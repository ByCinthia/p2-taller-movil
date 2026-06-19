import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/core/constantes/constantes_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/perfil_tecnico/vistas/detalle_servicio_empleado_screen.dart';

// ---------------------------------------------------------------------------
// Pantalla unificada de asignaciones del empleado
// Tabs: Mis Asignaciones | En Curso | Historial
// ---------------------------------------------------------------------------

class AsignacionesEmpleadoScreen extends StatefulWidget {
  final String tipoFiltro;

  const AsignacionesEmpleadoScreen({super.key, this.tipoFiltro = 'asignadas'});

  @override
  State<AsignacionesEmpleadoScreen> createState() =>
      _AsignacionesEmpleadoScreenState();
}

class _AsignacionesEmpleadoScreenState
    extends State<AsignacionesEmpleadoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _asignacionesFuture;

  @override
  void initState() {
    super.initState();
    final initialTab = _tabIndexForFiltro(widget.tipoFiltro);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialTab);
    _cargarAsignaciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _tabIndexForFiltro(String filtro) {
    if (filtro == 'curso') return 1;
    if (filtro == 'historial') return 2;
    return 0;
  }

  void _cargarAsignaciones() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      _asignacionesFuture = ApiService(token: auth.token).getMyAsignaciones();
    } else {
      _asignacionesFuture = Future.value([]);
    }
  }

  Future<void> _refresh() async {
    setState(_cargarAsignaciones);
    await _asignacionesFuture;
  }

  // ── Filtros de estado ────────────────────────────────────────────────────

  static const _estadosHistorial = {
    'finalizada', 'finalizado', 'completada', 'completado',
    'atendido', 'atendida', 'cancelada', 'cancelado',
  };

  static const _estadosCurso = {'aceptada', 'aceptado'};

  static const _estadosMisAsignaciones = {'asignada', 'asignado', 'pendiente'};

  List<Map<String, dynamic>> _filtrar(
    List<Map<String, dynamic>> items,
    String tipo,
  ) {
    return items.where((item) {
      final tarea = (item['estado_tarea'] ?? '').toString().toLowerCase();
      final incidente =
          (item['incidente_estado'] ?? item['estado'] ?? '').toString().toLowerCase();

      // Historial: tarea o incidente debe estar en estados finales
      final esHistorial =
          _estadosHistorial.contains(tarea) || _estadosHistorial.contains(incidente);

      // En curso: tarea = aceptada (incidente puede ser aceptada)
      final esCurso =
          _estadosCurso.contains(tarea) || _estadosCurso.contains(incidente);

      // Mis asignaciones: pendientes/asignadas
      final esPendiente = _estadosMisAsignaciones.contains(tarea) ||
          _estadosMisAsignaciones.contains(incidente);

      if (tipo == 'historial') return esHistorial;
      if (tipo == 'curso') return esCurso && !esHistorial;
      // 'asignadas': no historial, no curso
      return esPendiente && !esCurso && !esHistorial;
    }).toList();
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('Mis Asignaciones'),
        backgroundColor: const Color(0xFF1A1D27),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Pendientes', icon: Icon(Icons.inbox, size: 18)),
            Tab(text: 'En Curso', icon: Icon(Icons.run_circle, size: 18)),
            Tab(text: 'Historial', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _asignacionesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final todos = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 0: Mis Asignaciones (pendientes/asignadas)
              _ListaAsignaciones(
                items: _filtrar(todos, 'asignadas'),
                onRefresh: _refresh,
                tipo: 'asignadas',
              ),
              // ── Tab 1: Servicios en Curso (aceptadas)
              _ListaAsignaciones(
                items: _filtrar(todos, 'curso'),
                onRefresh: _refresh,
                tipo: 'curso',
              ),
              // ── Tab 2: Historial (finalizados/atendidos)
              _ListaAsignaciones(
                items: _filtrar(todos, 'historial'),
                onRefresh: _refresh,
                tipo: 'historial',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(err,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _refresh, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

// ===========================================================================
// Lista de asignaciones para un tab
// ===========================================================================

class _ListaAsignaciones extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;
  final String tipo; // 'asignadas' | 'curso' | 'historial'

  const _ListaAsignaciones({
    required this.items,
    required this.onRefresh,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF6C63FF),
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                _EmptyState(tipo: tipo),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                return _TarjetaAsignacion(
                  item: items[idx],
                  tipo: tipo,
                  onRefresh: onRefresh,
                );
              },
            ),
    );
  }
}

// ===========================================================================
// Tarjeta individual de asignación
// ===========================================================================

class _TarjetaAsignacion extends StatefulWidget {
  final Map<String, dynamic> item;
  final String tipo;
  final Future<void> Function() onRefresh;

  const _TarjetaAsignacion({
    required this.item,
    required this.tipo,
    required this.onRefresh,
  });

  @override
  State<_TarjetaAsignacion> createState() => _TarjetaAsignacionState();
}

class _TarjetaAsignacionState extends State<_TarjetaAsignacion> {
  bool _procesando = false;

  String get _incidenteId =>
      (widget.item['incidente_id'] ?? widget.item['incidente'] ?? '')
          .toString();

  // ── Aceptar asignación ───────────────────────────────────────────────────
  Future<void> _aceptar() async {
    await _ejecutarAccion(() async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await http
          .post(
            Uri.parse(
                '${AppConstants.baseUrl}/api/incidentes/$_incidenteId/aceptar-solicitud'),
            headers: {
              'Authorization': 'Bearer ${auth.token}',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.requestTimeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _snack('Asignación aceptada', color: Colors.green[700]!);
      } else {
        final body = jsonDecode(res.body);
        throw Exception(body['detail'] ?? 'Error ${res.statusCode}');
      }
    });
  }

  // ── Rechazar (cancelar-aceptacion) ───────────────────────────────────────
  Future<void> _rechazar() async {
    final confirm = await _confirmar(
      '¿Rechazar asignación?',
      'Esto devolverá la solicitud al estado pendiente.',
    );
    if (!confirm) return;

    await _ejecutarAccion(() async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await http
          .post(
            Uri.parse(
                '${AppConstants.baseUrl}/api/incidentes/$_incidenteId/cancelar-aceptacion'),
            headers: {
              'Authorization': 'Bearer ${auth.token}',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.requestTimeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _snack('Asignación rechazada');
      } else {
        final body = jsonDecode(res.body);
        throw Exception(body['detail'] ?? 'Error ${res.statusCode}');
      }
    });
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  Future<void> _ejecutarAccion(Future<void> Function() accion) async {
    setState(() => _procesando = true);
    try {
      await accion();
      await widget.onRefresh();
    } catch (e) {
      _snack('Error: $e', color: Colors.red[700]!);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? Colors.green[700],
    ));
  }

  Future<bool> _confirmar(String titulo, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(titulo),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmar')),
            ],
          ),
        ) ??
        false;
  }

  void _verDetalle() {
    if (_incidenteId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetalleServicioEmpleadoScreen(incidenteId: _incidenteId),
      ),
    ).then((_) => widget.onRefresh());
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tipo = widget.tipo;
    final estadoTarea = (item['estado_tarea'] ?? '').toString();
    final estadoInc = (item['incidente_estado'] ?? item['estado'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['incidente_tipo'] ?? item['tipo'] ?? 'Servicio',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['incidente_descripcion'] ??
                            item['descripcion'] ??
                            'Sin descripción',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _EstadoBadge(estado: estadoTarea.isNotEmpty ? estadoTarea : estadoInc),
              ],
            ),

            const SizedBox(height: 12),

            // ── Chips info ───────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if ((item['servicio_nombre'] ?? '').toString().isNotEmpty)
                  _Chip(
                      icon: Icons.build,
                      label: item['servicio_nombre'].toString()),
                if ((item['fecha_asignacion'] ?? '').toString().isNotEmpty)
                  _Chip(
                      icon: Icons.calendar_today,
                      label: _formatFecha(item['fecha_asignacion'].toString())),
                if ((item['distancia_km'] ?? '').toString().isNotEmpty &&
                    item['distancia_km'] != null)
                  _Chip(
                      icon: Icons.social_distance,
                      label: '${item['distancia_km']} km'),
              ],
            ),

            const SizedBox(height: 14),

            // ── Acciones según tab ───────────────────────────────────
            _buildAcciones(tipo),
          ],
        ),
      ),
    );
  }

  Widget _buildAcciones(String tipo) {
    if (_procesando) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
    }

    // Historial → sin acciones
    if (tipo == 'historial') {
      return const Text('Servicio cerrado',
          style: TextStyle(color: Colors.white38, fontSize: 12));
    }

    // En curso → Ver Detalle
    if (tipo == 'curso') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _verDetalle,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Ver Detalle / Continuar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    // Pendientes/Asignadas → Aceptar + Rechazar + Ver Detalle
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionBtn(
          label: 'Aceptar',
          icon: Icons.check,
          color: Colors.green[700]!,
          onPressed: _aceptar,
        ),
        _ActionBtn(
          label: 'Rechazar',
          icon: Icons.close,
          color: Colors.red[700]!,
          onPressed: _rechazar,
        ),
        _ActionBtn(
          label: 'Ver Detalle',
          icon: Icons.info_outline,
          color: const Color(0xFF6C63FF),
          onPressed: _verDetalle,
        ),
      ],
    );
  }

  String _formatFecha(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ===========================================================================
// WIDGETS AUXILIARES
// ===========================================================================

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  Color _color() {
    final s = estado.toLowerCase();
    if (s.contains('aceptada') || s.contains('aceptado')) {
      return const Color(0xFF6C63FF);
    }
    if (s.contains('pendiente') || s.contains('asignada')) {
      return Colors.orange;
    }
    if (s.contains('finaliz') || s.contains('atendid') || s.contains('complet')) {
      return Colors.green;
    }
    if (s.contains('cancel')) return Colors.red;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.6)),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
            color: c, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white54),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String tipo;
  const _EmptyState({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final msgs = {
      'asignadas': ('No hay solicitudes pendientes', Icons.inbox_outlined),
      'curso': ('No tienes servicios en curso', Icons.run_circle_outlined),
      'historial': ('No hay historial de servicios', Icons.history_outlined),
    };
    final (msg, icon) = msgs[tipo] ?? ('Sin datos', Icons.hourglass_empty);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(color: Colors.white38, fontSize: 15),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
