class EscaneoPLanta {
  final int id;
  final String? imagenBase64;
  final String resultado;
  final double confianza;
  final String? instrucciones;
  final int pasoNumero;
  final bool esFotoSeguimiento;
  final bool tratamientoCompletado;
  final String fechaEscaneo;

  EscaneoPLanta({
    required this.id,
    this.imagenBase64,
    required this.resultado,
    required this.confianza,
    this.instrucciones,
    required this.pasoNumero,
    required this.esFotoSeguimiento,
    required this.tratamientoCompletado,
    required this.fechaEscaneo,
  });

  factory EscaneoPLanta.fromJson(Map<String, dynamic> json) {
    return EscaneoPLanta(
      id: json['id'],
      imagenBase64: json['imagen_base64'],
      resultado: json['resultado'],
      confianza: (json['confianza'] is int)
          ? (json['confianza'] as int).toDouble()
          : (json['confianza'] as num).toDouble(),
      instrucciones: json['instrucciones'],
      pasoNumero: json['paso_numero'] ?? 0,
      esFotoSeguimiento: json['es_foto_seguimiento'] ?? false,
      tratamientoCompletado: json['tratamiento_completado'] ?? false,
      fechaEscaneo: json['fecha_escaneo'],
    );
  }

  bool get estaSana => resultado == 'Sana';
}
