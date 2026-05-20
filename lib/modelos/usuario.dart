class Usuario {
  final int id;
  final String nombreUsuario;

  Usuario({
    required this.id,
    required this.nombreUsuario,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombreUsuario: json['nombre_usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_usuario': nombreUsuario,
    };
  }
}