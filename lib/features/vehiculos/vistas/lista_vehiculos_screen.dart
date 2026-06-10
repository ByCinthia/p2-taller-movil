import 'package:flutter/material.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/servicios/vehiculo_service.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/modelos/vehiculo.dart';
import 'package:provider/provider.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';

class VehiclesListScreen extends StatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  Future<List<Vehicle>>? _future;

  @override
  void initState() {
    super.initState();
    // Load using VehiculoService with token from AuthProvider (pulled in build if needed)
    // Initial value will be set in didChangeDependencies where we can access Provider.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final token = auth.token;
    setState(() {
      _future = VehiculoService(token: token).getMisVehiculos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehículos')),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Vehicle>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty)
            return const Center(child: Text('No hay vehículos'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final v = vehicles[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(v.principal ? Icons.star : Icons.directions_car),
                ),
                title: Text('${v.marca ?? 'N/A'} ${v.modelo ?? ''}'.trim()),
                subtitle: Text(
                  'Placa: ${v.placa ?? 'N/A'} • Año: ${v.anio ?? 'N/A'}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (choice) async {
                    final auth = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final svc = VehiculoService(token: auth.token);
                    if (choice == 'editar') {
                      // abrir formulario de edición (reusar VehicleRegisterScreen)
                      final updated = await Navigator.pushNamed(
                        context,
                        '/registrar-vehiculo',
                        arguments: v,
                      );
                      if (updated == true)
                        setState(() => _future = svc.getMisVehiculos());
                    } else if (choice == 'eliminar') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmar'),
                          content: const Text('¿Eliminar este vehículo?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await svc.eliminarVehiculo(v.id);
                          if (!mounted) return;
                          setState(() => _future = svc.getMisVehiculos());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehículo eliminado')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: vehicles.length,
          );
        },
      ),
    );
  }
}
