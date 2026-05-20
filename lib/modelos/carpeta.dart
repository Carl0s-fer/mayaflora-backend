class Carpeta {
  final int id;
  final String nombre;
  final String fechaCreacion;
  final int totalPlantas;

  Carpeta({
    required this.id,
    required this.nombre,
    required this.fechaCreacion,
    required this.totalPlantas,
  });

  factory Carpeta.fromJson(Map<String, dynamic> json) {
    return Carpeta(
      id: json['id'],
      nombre: json['nombre'],
      fechaCreacion: json['fecha_creacion'],
      totalPlantas: json['total_plantas'] ?? 0,
    );
  }
}
