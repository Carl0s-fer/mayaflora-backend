class Planta {
  final int id;
  final String nombre;
  final String? fotoPerfil;
  final String estadoActual;
  final int pasoTratamientoActual;
  final bool notificacionesActivas;
  final String fechaCreacion;
  final String? fechaUltimoEscaneo;

  Planta({
    required this.id,
    required this.nombre,
    this.fotoPerfil,
    required this.estadoActual,
    required this.pasoTratamientoActual,
    required this.notificacionesActivas,
    required this.fechaCreacion,
    this.fechaUltimoEscaneo,
  });

  factory Planta.fromJson(Map<String, dynamic> json) {
    return Planta(
      id: json['id'],
      nombre: json['nombre'],
      fotoPerfil: json['foto_perfil_base64'],
      estadoActual: json['estado_actual'] ?? 'Sin diagnostico',
      pasoTratamientoActual: json['paso_tratamiento_actual'] ?? 0,
      notificacionesActivas: json['notificaciones_activas'] ?? false,
      fechaCreacion: json['fecha_creacion'],
      fechaUltimoEscaneo: json['fecha_ultimo_escaneo'],
    );
  }

  bool get estaSana => estadoActual == 'Sana';
  bool get estaEnferma => estadoActual == 'Enferma';
  bool get sinDiagnostico => estadoActual == 'Sin diagnostico';
}
