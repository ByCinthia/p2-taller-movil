class Vehicle {
  final String id;
  final String clienteId;
  final int? anio;
  final String? placa;
  final String? marca;
  final String? modelo;
  final bool principal;

  Vehicle({
    required this.id,
    required this.clienteId,
    this.anio,
    this.placa,
    this.marca,
    this.modelo,
    required this.principal,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final rawAnio = json['anio'];
    return Vehicle(
      id: (json['id'] ?? '').toString(),
      clienteId: (json['cliente_id'] ?? '').toString(),
      anio: rawAnio is int ? rawAnio : int.tryParse(rawAnio?.toString() ?? ''),
      placa: json['placa']?.toString(),
      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),
      principal: json['principal'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anio': anio,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'principal': principal,
    };
  }
}
