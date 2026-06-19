import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/mapa_rastreo/servicios/websocket_tracking_service.dart';

// ---------------------------------------------------------------------------
// Pantalla de detalle de un servicio/incidente asignado al empleado.
// Permite: Iniciar Recorrido → Llegué al Sitio → Finalizar Servicio
// ---------------------------------------------------------------------------

class DetalleServicioEmpleadoScreen extends StatefulWidget {
  final String incidenteId;
  const DetalleServicioEmpleadoScreen({super.key, required this.incidenteId});

  @override
  State<DetalleServicioEmpleadoScreen> createState() =>
      _DetalleServicioEmpleadoScreenState();
}

// ---------------------------------------------------------------------------
// Etapas visuales (no persisten en BD; sólo "atendido" persiste al finalizar)
// ---------------------------------------------------------------------------
enum _EtapaVisual { espera, enCamino, enSitio, finalizado }

class _DetalleServicioEmpleadoScreenState
    extends State<DetalleServicioEmpleadoScreen> {
  late Future<Map<String, dynamic>> _detalleFuture;
  _EtapaVisual _etapa = _EtapaVisual.espera;
  bool _procesando = false;
  bool _compartiendo = false;

  // GPS + WebSocket tracking
  final WebSocketTrackingService _wsService = WebSocketTrackingService();
  StreamSubscription<Position>? _gpsSub;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  @override
  void dispose() {
    _detenerTracking();
    _wsService.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------

  void _cargarDetalle() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = ApiService(token: auth.token);
    _detalleFuture = api.getIncidente(widget.incidenteId);
  }

  Future<void> _refresh() async {
    setState(_cargarDetalle);
    await _detalleFuture;
  }

  // =========================================================================
  // ACCIONES PRINCIPALES
  // =========================================================================

  /// Inicia el recorrido: pide GPS, conecta WebSocket y comienza a enviar
  /// ubicación cada 10 s. Estado visual → enCamino (no se guarda en BD).
  Future<void> _iniciarRecorrido() async {
    setState(() => _procesando = true);
    try {
      final ok = await _solicitarPermisoGps();
      if (!ok) {
        _mostrarSnack('Se necesita permiso de ubicación para iniciar recorrido', error: true);
        return;
      }

      _wsService.connect(widget.incidenteId);

      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _gpsSub = Geolocator.getPositionStream(locationSettings: settings).listen(
        (pos) => _wsService.sendLocation(pos.latitude, pos.longitude),
        onError: (_) => _detenerTracking(),
      );

      // Capturar token antes del await para evitar uso de context tras gap
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await ApiService(token: token).updateIncidenteEstado(
        widget.incidenteId,
        'en_camino',
        latitud: pos.latitude,
        longitud: pos.longitude,
      );

      setState(() {
        _etapa = _EtapaVisual.enCamino;
        _compartiendo = true;
      });
      _mostrarSnack('Recorrido iniciado — compartiendo ubicación');
    } catch (e) {
      _mostrarSnack('Error al iniciar recorrido: $e', error: true);
    } finally {
      setState(() => _procesando = false);
    }
  }

  /// Marca llegada visual (no BD). Detiene el stream GPS pero mantiene WS.
  void _llegueAlSitio() {
    setState(() {
      _etapa = _EtapaVisual.enSitio;
      _compartiendo = false;
    });
    _gpsSub?.cancel();
    _gpsSub = null;
    _mostrarSnack('¡Llegaste al sitio! El cliente fue notificado.');
  }

  /// Finaliza el servicio: envía "atendido" al backend y navega a historial.
  Future<void> _finalizarServicio() async {
    final confirm = await _confirmarDialog(
      '¿Finalizar servicio?',
      'Esto marcará el incidente como atendido. No podrás revertirlo.',
    );
    if (!confirm) return;

    setState(() => _procesando = true);
    try {
      _detenerTracking();
      // Capturar token antes del await para evitar uso de context tras gap
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await ApiService(token: token)
          .updateIncidenteEstado(widget.incidenteId, 'atendido');

      setState(() => _etapa = _EtapaVisual.finalizado);
      _mostrarSnack('Servicio finalizado correctamente');

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        // Redirige a la lista de historial
        Navigator.pushReplacementNamed(
          context,
          '/empleado/asignaciones',
          arguments: 'historial',
        );
      }
    } catch (e) {
      _mostrarSnack('Error al finalizar: $e', error: true);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  void _detenerTracking() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _wsService.disconnect();
    if (mounted) setState(() => _compartiendo = false);
  }

  Future<bool> _solicitarPermisoGps() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied &&
        perm != LocationPermission.deniedForever;
  }

  void _mostrarSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red[700] : Colors.green[700],
    ));
  }

  Future<bool> _confirmarDialog(String titulo, String mensaje) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
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

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('Detalle del Servicio'),
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
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detalleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const Center(
                child: Text('Sin datos', style: TextStyle(color: Colors.white54)));
          }

          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildError(String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
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

  Widget _buildContent(Map<String, dynamic> detalle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progreso visual ──────────────────────────────────────────
          _ProgressBar(etapa: _etapa, compartiendo: _compartiendo),
          const SizedBox(height: 20),

          // ── Incidente ────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.report_problem,
            iconColor: const Color(0xFFFF6B6B),
            titulo: 'Incidente',
            children: [
              _InfoRow('Tipo', detalle['tipo'] ?? 'N/A'),
              _InfoRow('Descripción', detalle['descripcion'] ?? 'Sin descripción'),
              _InfoRow('Estado', detalle['estado'] ?? 'N/A'),
              _InfoRow('Prioridad', detalle['prioridad'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Vehículo ─────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.directions_car,
            iconColor: const Color(0xFF6C63FF),
            titulo: 'Vehículo',
            children: [
              _InfoRow('ID Vehículo', detalle['vehiculo_id']?.toString() ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Ubicación del cliente ────────────────────────────────────
          _SectionCard(
            icon: Icons.location_on,
            iconColor: const Color(0xFF4ECDC4),
            titulo: 'Ubicación del cliente',
            children: [
              _InfoRow('Latitud', detalle['latitud']?.toString() ?? 'N/A'),
              _InfoRow('Longitud', detalle['longitud']?.toString() ?? 'N/A'),
              if (detalle['distancia_km'] != null)
                _InfoRow('Distancia', '${detalle['distancia_km']} km'),
              if (detalle['eta_minutos'] != null)
                _InfoRow('ETA', '${detalle['eta_minutos']} min'),
            ],
          ),
          const SizedBox(height: 24),

          // ── Botones de acción ────────────────────────────────────────
          _buildBotonesAccion(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    if (_etapa == _EtapaVisual.finalizado) {
      return _BtnFinalizado();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Indicador de compartición activa
        if (_compartiendo)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.my_location, color: Colors.greenAccent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Compartiendo ubicación en tiempo real…',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        // ── Iniciar Recorrido
        if (_etapa == _EtapaVisual.espera)
          _AccionBtn(
            label: 'Iniciar Recorrido',
            icon: Icons.directions_car,
            color: const Color(0xFF6C63FF),
            procesando: _procesando,
            onPressed: _iniciarRecorrido,
          ),

        // ── Llegué al Sitio
        if (_etapa == _EtapaVisual.enCamino) ...[
          _AccionBtn(
            label: 'Llegué al Sitio',
            icon: Icons.place,
            color: const Color(0xFF4ECDC4),
            procesando: _procesando,
            onPressed: () => _llegueAlSitio(),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _procesando ? null : _detenerTracking,
            icon: const Icon(Icons.stop, color: Colors.redAccent),
            label: const Text('Detener GPS',
                style: TextStyle(color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],

        // ── Finalizar Servicio
        if (_etapa == _EtapaVisual.enSitio)
          _AccionBtn(
            label: 'Finalizar Servicio',
            icon: Icons.check_circle,
            color: Colors.green[700]!,
            procesando: _procesando,
            onPressed: _finalizarServicio,
          ),
      ],
    );
  }
}

// ===========================================================================
// WIDGETS AUXILIARES
// ===========================================================================

class _ProgressBar extends StatelessWidget {
  final _EtapaVisual etapa;
  final bool compartiendo;
  const _ProgressBar({required this.etapa, required this.compartiendo});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('Asignado', Icons.assignment, _EtapaVisual.espera),
      _Step('En camino', Icons.navigation, _EtapaVisual.enCamino),
      _Step('En sitio', Icons.place, _EtapaVisual.enSitio),
      _Step('Finalizado', Icons.check_circle, _EtapaVisual.finalizado),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1D27), Color(0xFF252836)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estado del servicio',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Línea separadora
                final stepIdx = i ~/ 2;
                final active = steps[stepIdx].etapa.index <= etapa.index;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: active
                        ? const Color(0xFF6C63FF)
                        : Colors.white24,
                  ),
                );
              }
              final step = steps[i ~/ 2];
              final active = step.etapa.index <= etapa.index;
              final isCurrent = step.etapa == etapa;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF6C63FF)
                          : Colors.white12,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(step.icon,
                        color: active ? Colors.white : Colors.white38,
                        size: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(step.label,
                      style: TextStyle(
                          color: active ? Colors.white : Colors.white38,
                          fontSize: 10,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              );
            }),
          ),
          if (compartiendo) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('GPS activo',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            )
          ],
        ],
      ),
    );
  }
}

class _Step {
  final String label;
  final IconData icon;
  final _EtapaVisual etapa;
  const _Step(this.label, this.icon, this.etapa);
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String titulo;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(titulo,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _AccionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool procesando;
  final VoidCallback? onPressed;

  const _AccionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.procesando,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: procesando ? null : onPressed,
      icon: procesando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BtnFinalizado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[900]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
          SizedBox(height: 12),
          Text(
            'Servicio Finalizado',
            style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'El servicio ha sido marcado como atendido.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
