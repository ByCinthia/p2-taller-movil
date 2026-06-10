import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';
import 'package:auxiliomecanico_movil/features/administracion/vistas/panel_principal_admin_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            title: 'Panel Administrador',
            subtitle: 'Perfil del taller',
            user: user,
            initial: _initialFrom(user),
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
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Abrir panel de solicitudes'),
              subtitle: const Text('Ir a la vista operativa del administrador'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminHomeScreen(initialTab: 1),
                  ),
                );
              },
            ),
          ),
        ],
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
