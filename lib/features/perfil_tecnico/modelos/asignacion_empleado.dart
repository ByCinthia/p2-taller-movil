class EmployeeAssignment {
  final String id;
  final String username;
  final String email;
  final String fullName;

  EmployeeAssignment({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
  });

  factory EmployeeAssignment.fromJson(Map<String, dynamic> json) {
    final usuario = (json['usuario'] as Map<String, dynamic>?) ?? const {};
    final firstName = (usuario['first_name'] ?? '').toString().trim();
    final lastName = (usuario['last_name'] ?? '').toString().trim();
    final username = (usuario['username'] ?? '').toString().trim();
    final email = (usuario['email'] ?? '').toString().trim();
    final fullName = (json['nombre_completo'] ?? '').toString().trim();

    return EmployeeAssignment(
      id: json['id']?.toString() ?? '',
      username: username,
      email: email,
      fullName: fullName.isNotEmpty
          ? fullName
          : [firstName, lastName].where((part) => part.isNotEmpty).join(' ').trim().isNotEmpty
              ? [firstName, lastName].where((part) => part.isNotEmpty).join(' ').trim()
              : username,
    );
  }
}