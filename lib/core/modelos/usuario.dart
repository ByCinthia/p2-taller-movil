/// Modelo de usuario/empleado
class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role; // 'admin' o 'empleado'
  final String? empresaId;
  final String? clienteId;
  final bool isActive;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.empresaId,
    this.clienteId,
    required this.isActive,
    this.createdAt,
  });

  /// Crea un User desde JSON del backend
  factory User.fromJson(Map<String, dynamic> json) {
    print('📥 JSON recibido del backend para User: $json');
    
    // Determinar el rol basado en la estructura del backend
    String role = 'empleado'; // Rol por defecto
    
    // Primero revisar si es admin
    if (json['es_admin'] == true || json['is_admin'] == true) {
      role = 'admin';
      print('✅ Detectado como ADMIN');
    }
    // Si hay un role explícito en el JSON, usarlo
    else if (json['role'] != null) {
      final roleValue = json['role'].toString().toLowerCase().trim();
      if (roleValue.isNotEmpty) {
        role = roleValue;
        print('✅ Rol desde JSON: $roleValue -> asignado: $role');
      }
    }
    // Si no hay role explícito, revisar si es cliente (tiene cliente_id)
    else if (json['cliente_id'] != null && json['cliente_id'].toString().isNotEmpty) {
      role = 'cliente';
      print('✅ Detectado como CLIENTE (por cliente_id)');
    }
    
    print('🎯 Rol final asignado: $role');

    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawEmpresaId = json['empresa_id'];
    final parsedEmpresaId = rawEmpresaId == null ? null : rawEmpresaId.toString();

    final rawClienteId = json['cliente_id'];
    final parsedClienteId = rawClienteId == null ? null : rawClienteId.toString();

    final rawCreatedAt = json['created_at'];
    DateTime? parsedCreatedAt;
    if (rawCreatedAt != null && rawCreatedAt.toString().isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt.toString());
    }
    
    return User(
      id: parsedId,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: role,
      empresaId: parsedEmpresaId,
      clienteId: parsedClienteId,
      isActive: json['is_active'] ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'es_admin': role == 'admin',
      'empresa_id': empresaId,
      'cliente_id': clienteId,
      'is_active': isActive,
    };
  }

  /// Nombre completo del usuario
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? username;
  }

  @override
  String toString() => 'User(id: $id, username: $username, role: $role)';
}
