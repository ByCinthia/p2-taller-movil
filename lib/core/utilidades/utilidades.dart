/// Utilidades y funciones helper
import 'package:flutter/material.dart';

/// Muestra un SnackBar con mensaje de error
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Muestra un SnackBar con mensaje de éxito
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Muestra un SnackBar informativo
void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Muestra un diálogo de confirmación
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

/// Formatea una fecha a formato legible
String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

/// Formatea una fecha y hora a formato legible
String formatDateTime(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// Valida una dirección de email
bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return emailRegex.hasMatch(email);
}

/// Obtiene la iniciales de un nombre
String getInitials(String name) {
  List<String> parts = name.split(' ');
  String initials = '';
  for (var part in parts) {
    if (part.isNotEmpty) {
      initials += part[0].toUpperCase();
    }
  }
  return initials.length > 2 ? initials.substring(0, 2) : initials;
}
