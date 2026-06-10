import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔷 [ProfileScreen] initState - widget being initialized');
  }

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
    debugPrint('🔷 [ProfileScreen] build() starting...');
    try {
      final auth = Provider.of<AuthProvider>(context);
      final user = auth.user;
      debugPrint('🔷 [ProfileScreen] build() - user: $user');

      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        drawer: const AppDrawer(),
        body: _ClientProfileView(user: user, initial: _initialFrom(user)),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileScreen] Error en build: $e');
      debugPrint('Stack: $stackTrace');
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Error cargando perfil: $e'),
        ),
      );
    }
  }
}

class _ClientProfileView extends StatelessWidget {
  final User? user;
  final String initial;

  const _ClientProfileView({required this.user, required this.initial});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔷 [_ClientProfileView] build() - user: $user');
    try {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            title: 'Portal de cliente',
            subtitle: 'Perfil y gestión de solicitudes',
            user: user,
            initial: initial,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mi perfil', style: Theme.of(context).textTheme.titleMedium),
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
              leading: const Icon(Icons.report),
              title: const Text('Solicitar auxilio'),
              subtitle: const Text('Crear una nueva solicitud de auxilio'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/solicitud-auxilio'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Seguimiento de solicitudes'),
              subtitle: const Text('Ver tus solicitudes y su estado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/historial-incidentes'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Mis notificaciones'),
              subtitle: const Text('Ver alertas y avisos recibidos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/notificaciones'),
            ),
          ),
        ],
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [_ClientProfileView] Error: $e');
      debugPrint('Stack: $stackTrace');
      return Center(
        child: Text('Error en vista: $e'),
      );
    }
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