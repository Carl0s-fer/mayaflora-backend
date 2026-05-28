class Carpeta {
  final int id;
  final String nombre;
  final String fechaCreacion;
  final int totalPlantas;
  final int plantasEnfermas;
  final int plantasSanas;

  Carpeta({
    required this.id,
    required this.nombre,
    required this.fechaCreacion,
    required this.totalPlantas,
    required this.plantasEnfermas,
    required this.plantasSanas,
  });

  factory Carpeta.fromJson(Map<String, dynamic> json) {
    return Carpeta(
      id: json['id'],
      nombre: json['nombre'],
      fechaCreacion: json['fecha_creacion'],
      totalPlantas: json['total_plantas'] ?? 0,
      plantasEnfermas: json['plantas_enfermas'] ?? 0,
      plantasSanas: json['plantas_sanas'] ?? 0,
    );
  }

  // Vacía: sin border
  // Con alguna enferma: borde rojo
  // Todas sanas (y hay al menos una): borde verde
  bool get estaVacia => totalPlantas == 0;
  bool get tieneEnfermas => plantasEnfermas > 0;
  bool get todasSanas => totalPlantas > 0 && plantasEnfermas == 0 && plantasSanas == totalPlantas;
}
