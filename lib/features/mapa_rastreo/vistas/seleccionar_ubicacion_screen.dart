import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  const SeleccionarUbicacionScreen({super.key});

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  final MapController _mapController = MapController();
  LatLng? _selected;

  static final LatLng _initialCenter = LatLng(-17.7833, -63.1821);
  double _zoom = 13;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selected = p;
      });
      _mapController.move(p, 16);
    } catch (_) {
      // ignore and allow user to tap the map
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicación')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: _zoom,
          minZoom: 3,
          onTap: (tapPos, latLng) {
            setState(() {
              _selected = latLng;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.auxiliomecanico_movil',
          ),
          if (_selected != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 48,
                  height: 48,
                  point: _selected!,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text('Usar ubicación'),
        onPressed: _selected == null
            ? null
            : () {
                Navigator.pop(context, {
                  'latitud': _selected!.latitude,
                  'longitud': _selected!.longitude,
                });
              },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
