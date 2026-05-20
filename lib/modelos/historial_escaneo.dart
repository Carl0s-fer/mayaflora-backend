class HistorialEscaneo {
  final int id;
  final String nombreUsuario;
  final String resultado;
  final double confianza;
  final String fechaEscaneo;

  HistorialEscaneo({
    required this.id,
    required this.nombreUsuario,
    required this.resultado,
    required this.confianza,
    required this.fechaEscaneo,
  });

  factory HistorialEscaneo.fromJson(Map<String, dynamic> json) {
    return HistorialEscaneo(
      id: json['id'],
      nombreUsuario: json['nombre_usuario'],
      resultado: json['resultado'],
      confianza: json['confianza'].toDouble(),
      fechaEscaneo: json['fecha_escaneo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_usuario': nombreUsuario,
      'resultado': resultado,
      'confianza': confianza,
      'fecha_escaneo': fechaEscaneo,
    };
  }

  String get fechaFormateada {
    try {
      DateTime fecha = DateTime.parse(fechaEscaneo);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaEscaneo;
    }
  }

  bool get estaEnferma => resultado.toLowerCase() == 'enferma';
}