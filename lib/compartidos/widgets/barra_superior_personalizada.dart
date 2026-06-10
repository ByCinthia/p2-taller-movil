import 'package:flutter/material.dart';
import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';

/// AppBar personalizado con opciones del usuario
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final User? user;
  final VoidCallback? onLogout;
  final List<Widget>? actions;

  const CustomAppBar({
    required this.title,
    this.user,
    this.onLogout,
    this.actions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      elevation: 0,
      actions: [
        PopupMenuButton(
          itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
            if (user != null)
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            if (user != null) const PopupMenuDivider(),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Perfil'),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/perfil');
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 12),
                  Text('Configuración'),
                ],
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración en desarrollo')),
                );
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Ayuda'),
                ],
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ayuda en desarrollo')),
                );
              },
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: onLogout,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
