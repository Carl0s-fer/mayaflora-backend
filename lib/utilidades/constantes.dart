import 'package:flutter/material.dart';

// URL del backend - CAMBIA ESTA IP POR LA IP DE TU COMPUTADORA
// Para encontrar tu IP en Windows, abre CMD y escribe: ipconfig
// Busca "Dirección IPv4" en tu adaptador de red activo
//const String BASE_URL = "http://10.0.2.2:5000"; // CAMBIA ESTA IP
const String BASE_URL = 'https://mayaflora-api.onrender.com'; // CAMBIA ESTA IP

// Endpoints de la API
const String LOGIN_ENDPOINT = '/api/login';
const String REGISTRO_ENDPOINT = '/api/registro';
const String ANALIZAR_ENDPOINT = '/api/analizar';
const String HISTORIAL_ENDPOINT = '/api/historial';
const String ESTADISTICAS_ENDPOINT = '/api/estadisticas';

// Colores de Mayaflora
class ColoresMayaflora {
  static const Color primario = Color(0xFF2E7D32); // Verde oscuro
  static const Color secundario = Color(0xFF66BB6A); // Verde claro
  static const Color acento = Color(0xFFFFB300); // Amarillo/dorado
  static const Color fondo = Color(0xFFF5F5F5); // Gris muy claro
  static const Color error = Color(0xFFD32F2F); // Rojo
  static const Color exito = Color(0xFF388E3C); // Verde éxito
  static const Color texto = Color(0xFF212121); // Negro texto
  static const Color textoSecundario = Color(0xFF757575); // Gris texto
  static const Color blanco = Colors.white;
}

// Estilos de texto
class EstilosMayaflora {
  static const TextStyle titulo = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: ColoresMayaflora.primario,
  );

  static const TextStyle subtitulo = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ColoresMayaflora.texto,
  );

  static const TextStyle cuerpo = TextStyle(
    fontSize: 16,
    color: ColoresMayaflora.texto,
  );

  static const TextStyle boton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: ColoresMayaflora.blanco,
  );
}

// Espaciados
class EspaciadosMayaflora {
  static const double pequeno = 8.0;
  static const double mediano = 16.0;
  static const double grande = 24.0;
  static const double extraGrande = 32.0;
}

// Mensajes
class MensajesMayaflora {
  static const String bienvenida = 'Bienvenido a Mayaflora';
  static const String descripcion = 'Detector de hongos en orquídeas';
  static const String errorConexion = 'Error de conexión con el servidor';
  static const String credencialesIncorrectas = 'Usuario o contraseña incorrectos';
  static const String camposVacios = 'Por favor completa todos los campos';
}