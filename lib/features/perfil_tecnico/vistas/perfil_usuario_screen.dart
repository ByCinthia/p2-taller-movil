import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/perfil_tecnico/vistas/asignaciones_tecnico_screen.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
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
              if (!context.mounted) {
                return;
              }
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
    final auth = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi perfil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Cerrar sesión',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Perfil'),
              Tab(text: 'Tareas'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: TabBarView(
          children: [
            _EmployeeProfileTab(auth: auth),
            const _EmployeeAssignmentsTab(),
          ],
        ),
      ),
    );
  }
}

class _EmployeeProfileTab extends StatefulWidget {
  final AuthProvider auth;

  const _EmployeeProfileTab({required this.auth});

  @override
  State<_EmployeeProfileTab> createState() => _EmployeeProfileTabState();
}

class _EmployeeProfileTabState extends State<_EmployeeProfileTab> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<Map<String, dynamic>> _empresaFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final token = widget.auth.token;
    if (token == null) {
      _profileFuture = Future.value(const <String, dynamic>{});
      _empresaFuture = Future.value(const <String, dynamic>{});
      return;
    }

    final api = ApiService(token: token);
    _profileFuture = api.getMyEmployeeProfile();
    _empresaFuture = api.getMyEmpresa();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([_profileFuture, _empresaFuture]),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
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
                    'No se pudo cargar el perfil del empleado',
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

        final profile = snapshot.data?[0] ?? const <String, dynamic>{};
        final empresa = snapshot.data?[1] ?? const <String, dynamic>{};
        final usuario = (profile['usuario'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
        final rolesAsignados = (profile['roles_asignados'] as List?)
                ?.whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList() ??
            const <Map<String, dynamic>>[];
        final displayName = (profile['nombre_completo'] ?? usuario['first_name'] ?? usuario['username'] ?? 'Empleado').toString();
        final avatarInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E';
        
        final double? tallerLat = (empresa['latitud'] as num?)?.toDouble();
        final double? tallerLon = (empresa['longitud'] as num?)?.toDouble();

        return RefreshIndicator(
          onRefresh: () async {
            setState(_loadProfile);
            await Future.wait([_profileFuture, _empresaFuture]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(
                          avatarInitial,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Perfil del empleado', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text('Datos reales de tu cuenta de trabajo', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Text(
                              displayName,
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
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'Datos personales',
                children: [
                  _InfoRow(label: 'Nombre', value: profile['nombre_completo']?.toString()),
                  _InfoRow(label: 'Cédula', value: profile['ci']?.toString()),
                  _InfoRow(label: 'Teléfono', value: profile['telefono']?.toString()),
                  _InfoRow(label: 'Dirección', value: profile['direccion']?.toString()),
                  _InfoRow(label: 'Cargo', value: profile['cargo_nombre']?.toString()),
                  _InfoRow(label: 'Empresa', value: (profile['empresa_nombre'] ?? profile['empresa'])?.toString()),
                ],
              ),
              if (tallerLat != null && tallerLon != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicación del Taller',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(tallerLat, tallerLon),
                                initialZoom: 15,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.auxiliomecanico',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(tallerLat, tallerLon),
                                      width: 40,
                                      height: 40,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Cuenta de acceso',
                children: [
                  _InfoRow(label: 'Usuario', value: usuario['username']?.toString()),
                  _InfoRow(label: 'Correo', value: usuario['email']?.toString()),
                  _InfoRow(label: 'Activo', value: usuario['is_active'] == true ? 'Sí' : 'No'),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Roles asignados',
                children: [
                  if (rolesAsignados.isEmpty)
                    const Text('Sin roles asignados')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rolesAsignados
                          .map((role) => Chip(label: Text((role['nombre'] ?? role['id'] ?? 'rol').toString())))
                          .toList(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Mis notificaciones'),
                  subtitle: const Text('Ver los avisos asignados a tu cuenta'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/notificaciones'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmployeeAssignmentsTab extends StatelessWidget {
  const _EmployeeAssignmentsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ver todas tus asignaciones'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AsignacionesEmpleadoScreen())),
              child: const Text('Abrir mis asignaciones'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
