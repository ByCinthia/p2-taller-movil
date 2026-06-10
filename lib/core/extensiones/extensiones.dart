/// Extensiones útiles para la aplicación

extension StringExtension on String {
  /// Capitaliza la primera letra de un string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Verifica si es un email válido
  bool isValidEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Verifica si es una contraseña fuerte
  bool isStrongPassword() {
    return length >= 8 && 
           contains(RegExp(r'[A-Z]')) && 
           contains(RegExp(r'[a-z]')) && 
           contains(RegExp(r'[0-9]'));
  }
}

extension ListExtension<T> on List<T> {
  /// Verifica si la lista no está vacía
  bool get isNotEmpty => length > 0;

  /// Obtiene el primer elemento o null
  T? get firstOrNull => isEmpty ? null : first;

  /// Obtiene el último elemento o null
  T? get lastOrNull => isEmpty ? null : last;
}

extension MapExtension on Map<String, dynamic> {
  /// Obtiene un valor con tipo seguro
  T? getValue<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    return null;
  }
}
