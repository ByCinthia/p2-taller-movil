import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/vistas/registrar_vehiculo_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final role = auth.userRole ?? '';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              auth.user?.fullName ?? 'Usuario',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            accountEmail: Text(
              auth.user?.email ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          if (role == 'cliente') ...[
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Mis vehículos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/vehiculos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Registrar vehículo'),
              onTap: () async {
                Navigator.pop(context);
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => const VehicleRegisterScreen(),
                  ),
                );
                if (created == true) {
                  // Reemplazar la ruta actual por la lista de vehículos para evitar apilar
                  Navigator.pushReplacementNamed(context, '/vehiculos');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Solicitud de auxilio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/solicitud-auxilio');
              },
            ),
          ],
          if (role == 'admin') ...[
            ListTile(
              leading: const Icon(Icons.directions_car_filled),
              title: const Text('Vehículos (operativo)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/vehiculos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Empleados'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/empleados');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Incidentes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/incidentes');
              },
            ),
          ],
          if (role == 'empleado') ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/empleado/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Solicitudes Asignadas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/empleado/asignaciones',
                  arguments: 'asignadas',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.car_repair),
              title: const Text('Servicio en Curso'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/empleado/asignaciones',
                  arguments: 'curso',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/empleado/asignaciones',
                  arguments: 'historial',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/empleado/perfil');
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notificaciones');
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/perfil');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              Navigator.pop(context);
              await auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
