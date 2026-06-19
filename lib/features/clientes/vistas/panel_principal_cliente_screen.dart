import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/modelos/vehiculo.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/barra_superior_personalizada.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  Future<List<Vehicle>> _vehiclesFuture = Future.value(<Vehicle>[]);

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      _vehiclesFuture = ApiService(token: auth.token).getMyVehicles();
    } else {
      _vehiclesFuture = Future.value(<Vehicle>[]);
    }
  }

  Future<void> _refreshVehicles() async {
    setState(_loadVehicles);
    await _vehiclesFuture;
  }

  Future<void> _openVehicleForm() async {
    // keep for backward compatibility if used elsewhere
    final saved = await Navigator.pushNamed<bool>(
      context,
      '/registrar-vehiculo',
    );
    if (saved == true && mounted) {
      setState(_loadVehicles);
    }
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Área de cliente',
        user: user,
        onLogout: _logout,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2196F3)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menú del cliente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/perfil');
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Mis vehículos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/vehiculos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Registrar vehículo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/registrar-vehiculo');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('Solicitud de auxilio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/solicitud-auxilio');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de incidentes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/historial-incidentes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Seguimiento del servicio'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to history to pick the active incident
                Navigator.pushNamed(context, '/historial-incidentes');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Deseas salir de la app?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/solicitud-auxilio'),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning),
        label: const Text('Pedir auxilio'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshVehicles,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${user?.fullName ?? 'Cliente'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí puedes ver tus vehículos y pedir auxilio cuando lo necesites',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos de acceso',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Usuario',
                        value: user?.username ?? 'N/A',
                      ),
                      _InfoRow(
                        label: 'Correo',
                        value: user?.email.isNotEmpty == true
                            ? user!.email
                            : 'N/A',
                      ),
                      _InfoRow(
                        label: 'Estado',
                        value: (user?.isActive ?? false)
                            ? 'Activo'
                            : 'Inactivo',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Mis vehículos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Vehicle>>(
                future: _vehiclesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final vehicles = snapshot.data ?? [];
                  if (vehicles.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No tienes vehículos registrados todavía.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              vehicle.principal
                                  ? Icons.star
                                  : Icons.directions_car,
                            ),
                          ),
                          title: Text(
                            '${vehicle.marca ?? 'N/A'} ${vehicle.modelo ?? ''}'
                                .trim(),
                          ),
                          subtitle: Text(
                            'Placa: ${vehicle.placa ?? 'N/A'}\nAño: ${vehicle.anio?.toString() ?? 'N/A'}',
                          ),
                          trailing: vehicle.principal
                              ? const Chip(label: Text('Principal'))
                              : null,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: vehicles.length,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
