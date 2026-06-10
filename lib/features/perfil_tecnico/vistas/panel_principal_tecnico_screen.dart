import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/mapa_rastreo/estado/ubicacion_proveedor.dart';
import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';
import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/barra_superior_personalizada.dart';

/// Pantalla Home para Empleado
class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  String? _errorMessage;

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mi Área de Trabajo',
        user: user,
        onLogout: () => _handleLogout(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            Text(
              'Bienvenido, ${user?.fullName ?? 'Empleado'}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona tu información y tareas desde aquí',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),

            // Tarjeta de información del empleado
            _EmployeeInfoCard(user: user),

            const SizedBox(height: 24),

            // Botón de actualizar ubicación
            Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                return Card(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber.withOpacity(0.05),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.amber.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mi Ubicación',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (locationProvider.lastLocationUpdate !=
                                      null)
                                    Text(
                                      'Última actualización: ${locationProvider.lastLocationUpdate!.toLocal().toString().split('.')[0]}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (locationProvider.locationError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                locationProvider.locationError ?? '',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: locationProvider.isUpdatingLocation
                                ? null
                                : () async {
                                    final success = await locationProvider
                                        .obtenerYActualizarUbicacion();
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ubicación actualizada',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                            icon: locationProvider.isUpdatingLocation
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.amber.shade700,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(
                              locationProvider.isUpdatingLocation
                                  ? 'Actualizando...'
                                  : 'Actualizar Ubicación Ahora',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Secciones disponibles
            Text(
              'Funcionalidades',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _FeatureTile(
                  icon: Icons.person,
                  title: 'Perfil',
                  subtitle: 'Ver mis datos',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pushNamed(context, '/empleado/perfil');
                  },
                ),
                _FeatureTile(
                  icon: Icons.task,
                  title: 'Tareas',
                  subtitle: 'Mis tareas pendientes',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pushNamed(context, '/empleado/asignaciones');
                  },
                ),
                _FeatureTile(
                  icon: Icons.calendar_today,
                  title: 'Horario',
                  subtitle: 'Mi horario de trabajo',
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Horario en desarrollo'),
                      ),
                    );
                  },
                ),
                _FeatureTile(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Ver notificaciones',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pushNamed(context, '/notificaciones');
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sección de información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Información',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Esta es tu área de trabajo. Aquí puedes ver tu información, tareas asignadas y horario. Para más opciones, contacta a tu administrador.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar información del empleado
class _EmployeeInfoCard extends StatelessWidget {
  final User? user;

  const _EmployeeInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                        (user?.fullName ?? '').isNotEmpty
                            ? (user?.fullName ?? '')[0].toUpperCase()
                            : 'E',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Empleado',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${user?.username ?? 'username'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white30),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.email,
              label: 'Email',
              value: user?.email ?? 'N/A',
              textColor: Colors.white,
              labelColor: Colors.white70,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.badge,
              label: 'ID',
              value: '${user?.id ?? 'N/A'}',
              textColor: Colors.white,
              labelColor: Colors.white70,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.check_circle,
              label: 'Estado',
              value: (user?.isActive ?? false) ? 'Activo' : 'Inactivo',
              textColor: (user?.isActive ?? false) ? Colors.lightGreenAccent : Colors.redAccent,
              labelColor: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar una fila de información
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final Color labelColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(color: labelColor, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Widget para tarjeta de funcionalidad
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
