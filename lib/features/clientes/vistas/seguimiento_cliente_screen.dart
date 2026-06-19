import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/core/constantes/constantes_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';

// ---------------------------------------------------------------------------
// Pantalla de seguimiento de solicitud para el CLIENTE
// Muestra el workflow de 6 pasos + mapa con marcador del técnico en tiempo real
// ---------------------------------------------------------------------------

class SeguimientoClienteScreen extends StatefulWidget {
  final String incidenteId;

  const SeguimientoClienteScreen({super.key, required this.incidenteId});

  @override
  State<SeguimientoClienteScreen> createState() =>
      _SeguimientoClienteScreenState();
}

class _SeguimientoClienteScreenState
    extends State<SeguimientoClienteScreen> {
  // ── Estado del incidente ──────────────────────────────────────────────────
  Map<String, dynamic>? _tracking;
  bool _cargando = true;
  String? _error;
  DateTime? _ultimaActualizacion;

  // ── WebSocket ─────────────────────────────────────────────────────────────
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;

  // ── Mapa ──────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _cargarTracking();
    _conectarWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  // =========================================================================
  // CARGA INICIAL Y WEBSOCKET
  // =========================================================================

  Future<void> _cargarTracking() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final api = ApiService(token: auth.token);
      final data = await api.getIncidente(widget.incidenteId);
      if (mounted) {
        setState(() {
          _tracking = data;
          _cargando = false;
          _ultimaActualizacion = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  void _conectarWs() {
    try {
      final base = AppConstants.baseUrl;
      final wsProtocol = base.startsWith('https://') ? 'wss://' : 'ws://';
      final cleanBase = base.replaceFirst(RegExp(r'https?://'), '');
      // Usando el WS del cliente: /api/ws/tracking/{id}/cliente
      final wsUrl =
          '$wsProtocol$cleanBase/api/ws/tracking/${widget.incidenteId}/cliente';

      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _wsSub = _wsChannel!.stream.listen(
        (msg) => _procesarMensajeWs(msg),
        onError: (_) => _reconectarWs(),
        onDone: () => _reconectarWs(),
      );
    } catch (_) {
      // Silencia errores de conexión WS
    }
  }

  void _reconectarWs() {
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _conectarWs();
    });
  }

  void _procesarMensajeWs(dynamic raw) {
    try {
      final Map<String, dynamic> msg =
          raw is String ? jsonDecode(raw) : (raw as Map<String, dynamic>);
      final tracking = msg['tracking'] as Map<String, dynamic>?;
      if (tracking != null && mounted) {
        setState(() {
          _tracking = {...?_tracking, ...tracking};
          _ultimaActualizacion = DateTime.now();
        });
        // Mover cámara si hay nuevas coords del técnico
        final tLat = (tracking['tecnico_latitud'] as num?)?.toDouble();
        final tLon = (tracking['tecnico_longitud'] as num?)?.toDouble();
        if (tLat != null && tLon != null) {
          _mapController.move(LatLng(tLat, tLon), _mapController.camera.zoom);
        }
      }
    } catch (_) {}
  }

  // =========================================================================
  // HELPERS DE ESTADO
  // =========================================================================

  String get _estadoIncidente =>
      (_tracking?['estado'] ?? '').toString().toLowerCase();

  String get _estadoVisual =>
      (_tracking?['visual_state'] ?? _estadoIncidente).toString().toLowerCase();

  // Paso activo del workflow (0–5)
  int get _pasoActual {
    final s = _estadoVisual;
    if (s == 'pendiente') return 0;
    if (s == 'aceptada') return 1;
    if (s == 'asignada') return 2;
    if (s == 'en_camino') return 3;
    if (s == 'en_sitio') return 4;
    if (['atendido', 'atendida', 'finalizado', 'finalizada', 'completada', 'completado']
        .contains(s)) return 5;
    return 0;
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text('Seguimiento de solicitud'),
        backgroundColor: const Color(0xFF1A1D27),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTracking,
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _error != null
              ? _buildError()
              : _buildContenido(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _cargarTracking, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    final incLat = (_tracking?['latitud'] as num?)?.toDouble();
    final incLon = (_tracking?['longitud'] as num?)?.toDouble();
    final tecLat = (_tracking?['tecnico_latitud'] as num?)?.toDouble();
    final tecLon = (_tracking?['tecnico_longitud'] as num?)?.toDouble();

    return Column(
      children: [
        // ── Mapa ─────────────────────────────────────────────────────────
        Expanded(
          flex: 5,
          child: _buildMapa(incLat, incLon, tecLat, tecLon),
        ),

        // ── Panel inferior ───────────────────────────────────────────────
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Workflow 6 pasos
                _WorkflowProgress(pasoActual: _pasoActual),
                const SizedBox(height: 16),

                // ── Distancia / ETA
                _buildDistanciaEta(),

                const SizedBox(height: 12),

                // ── Última actualización
                if (_ultimaActualizacion != null)
                  Row(
                    children: [
                      const Icon(Icons.update, size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(
                        'Última actualización: ${_formatTime(_ultimaActualizacion!)}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // ── Info del incidente
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapa(
      double? incLat, double? incLon, double? tecLat, double? tecLon) {
    final hasInc = incLat != null && incLon != null;
    final hasTec = tecLat != null && tecLon != null;

    if (!hasInc) {
      return Container(
        color: const Color(0xFF1A1D27),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: Colors.white38, size: 40),
              SizedBox(height: 8),
              Text('Ubicación no disponible',
                  style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    // Dart flow analysis already promotes incLat/incLon after the early return.
    // For tec coords, extract non-nullable locals once checked.
    final iLat = incLat;
    final iLon = incLon;

    final centro = hasTec
        ? LatLng((iLat + tecLat!) / 2, (iLon + tecLon!) / 2)
        : LatLng(iLat, iLon);

    final markers = <Marker>[
      // Marcador del incidente (cliente)
      Marker(
        point: LatLng(iLat, iLon),
        width: 60,
        height: 60,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Tu ubicación',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.location_on, color: Colors.red, size: 28),
          ],
        ),
      ),
    ];

    if (hasTec) {
      final tLat = tecLat;
      final tLon = tecLon;
      markers.add(
        Marker(
          point: LatLng(tLat, tLon),
          width: 60,
          height: 60,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Técnico',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.directions_car,
                  color: Color(0xFF6C63FF), size: 28),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: centro,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'auxiliomecanico.app',
        ),
        if (hasInc && hasTec)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [LatLng(tecLat!, tecLon!), LatLng(iLat, iLon)],
                color: const Color(0xFF6C63FF).withValues(alpha: 0.6),
                strokeWidth: 3,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildDistanciaEta() {
    final distancia = _tracking?['distancia_km'];
    final eta = _tracking?['eta_minutos'];

    if (distancia == null && eta == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          if (distancia != null)
            _StatBlock(
              icon: Icons.social_distance,
              value: '$distancia km',
              label: 'Distancia',
            ),
          if (distancia != null && eta != null)
            const SizedBox(
                width: 16,
                child: VerticalDivider(color: Colors.white24, thickness: 1)),
          if (eta != null)
            _StatBlock(
              icon: Icons.access_time,
              value: '$eta min',
              label: 'ETA aprox.',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalles de la solicitud',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          _InfoRow('Estado', _tracking?['estado'] ?? 'N/A'),
          _InfoRow('ID', widget.incidenteId),
          if (_tracking?['tecnico_asignado_nombre'] != null)
            _InfoRow('Técnico', _tracking!['tecnico_asignado_nombre'].toString()),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

// ===========================================================================
// WORKFLOW PROGRESS — 6 pasos
// ===========================================================================

class _WorkflowProgress extends StatelessWidget {
  final int pasoActual; // 0–5

  const _WorkflowProgress({required this.pasoActual});

  static const _pasos = [
    _Paso('Solicitud\ncreada', Icons.receipt_long),
    _Paso('Taller\naceptó', Icons.store),
    _Paso('Técnico\nasignado', Icons.person_pin),
    _Paso('Técnico\nen camino', Icons.directions_car),
    _Paso('Técnico\nllegó', Icons.place),
    _Paso('Servicio\nfinalizado', Icons.check_circle),
  ];

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Estado de tu solicitud',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          // Pasos en 2 filas de 3
          Row(
            children: List.generate(_pasos.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIdx = i ~/ 2;
                final active = stepIdx < pasoActual;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: active
                        ? const Color(0xFF6C63FF)
                        : Colors.white24,
                  ),
                );
              }
              final paso = _pasos[i ~/ 2];
              final done = (i ~/ 2) < pasoActual;
              final current = (i ~/ 2) == pasoActual;
              final color = done || current
                  ? const Color(0xFF6C63FF)
                  : Colors.white24;

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFF6C63FF)
                          : current
                              ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                              : Colors.white12,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color,
                          width: current ? 2.5 : 1),
                      boxShadow: current
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(paso.icon,
                        color: done || current
                            ? Colors.white
                            : Colors.white38,
                        size: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    paso.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: done || current
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 9,
                      fontWeight: current
                          ? FontWeight.bold
                          : FontWeight.normal,
                      height: 1.3,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Paso {
  final String label;
  final IconData icon;
  const _Paso(this.label, this.icon);
}

// ===========================================================================
// WIDGETS AUXILIARES
// ===========================================================================

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatBlock({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
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
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
