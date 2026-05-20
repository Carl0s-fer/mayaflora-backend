import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../modelos/carpeta.dart';
import '../modelos/planta.dart';
import '../modelos/escaneo_planta.dart';

class ServicioApi {
  // ─── Autenticación ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String nombreUsuario, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL$LOGIN_ENDPOINT'),
        body: {'nombre_usuario': nombreUsuario, 'contrasena': contrasena},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'exito': true, 'usuario': Usuario.fromJson(data['usuario']), 'mensaje': data['mensaje']};
      }
      final data = json.decode(response.body);
      return {'exito': false, 'mensaje': data['mensaje'] ?? 'Error al iniciar sesión'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> registro(String nombreUsuario, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL$REGISTRO_ENDPOINT'),
        body: {'nombre_usuario': nombreUsuario, 'contrasena': contrasena},
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'exito': true, 'mensaje': data['mensaje']};
      }
      final data = json.decode(response.body);
      return {'exito': false, 'mensaje': data['mensaje'] ?? 'Error al registrar usuario'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ─── Análisis general ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> analizarImagen(
    String rutaImagen, int usuarioId, String nombreUsuario,
  ) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$BASE_URL$ANALIZAR_ENDPOINT'));
      request.files.add(await http.MultipartFile.fromPath('imagen', rutaImagen));
      request.fields['usuario_id'] = usuarioId.toString();
      request.fields['nombre_usuario'] = nombreUsuario;
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'exito': true,
          'resultado': data['resultado'],
          'confianza': (data['confianza'] is int)
              ? (data['confianza'] as int).toDouble()
              : data['confianza'].toDouble(),
          'mensaje': data['mensaje'],
          'detalle': data['detalle'],
          'tipo_objeto': data['tipo_objeto'] ?? 'hoja_orquidea',
        };
      }
      final data = json.decode(response.body);
      return {'exito': false, 'mensaje': data['detail'] ?? 'Error al analizar imagen'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> obtenerHistorial(int usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL$HISTORIAL_ENDPOINT/$usuarioId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'exito': true, 'historial': data['historial']};
      }
      return {'exito': false, 'mensaje': 'Error al obtener historial'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> obtenerEstadisticas(int usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL$ESTADISTICAS_ENDPOINT/$usuarioId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'exito': true, 'estadisticas': data['estadisticas']};
      }
      return {'exito': false, 'mensaje': 'Error al obtener estadísticas'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ─── Carpetas ─────────────────────────────────────────────────────────────

  Future<List<Carpeta>> obtenerCarpetas(int usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/api/carpetas/$usuarioId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['carpetas'] as List).map((c) => Carpeta.fromJson(c)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> crearCarpeta(int usuarioId, String nombre) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/carpetas'),
        body: {'usuario_id': usuarioId.toString(), 'nombre': nombre},
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> actualizarCarpeta(int carpetaId, String nombre) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/api/carpetas/$carpetaId'),
        body: {'nombre': nombre},
      );
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> eliminarCarpeta(int carpetaId) async {
    try {
      final response = await http.delete(Uri.parse('$BASE_URL/api/carpetas/$carpetaId'));
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  // ─── Plantas ──────────────────────────────────────────────────────────────

  Future<List<Planta>> obtenerPlantas(int carpetaId) async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/api/plantas/carpeta/$carpetaId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['plantas'] as List).map((p) => Planta.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> crearPlanta(
    int carpetaId, int usuarioId, String nombre, String? rutaFotoPerfil,
  ) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$BASE_URL/api/plantas'));
      request.fields['carpeta_id'] = carpetaId.toString();
      request.fields['usuario_id'] = usuarioId.toString();
      request.fields['nombre'] = nombre;
      if (rutaFotoPerfil != null) {
        request.files.add(await http.MultipartFile.fromPath('foto_perfil', rutaFotoPerfil));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return json.decode(response.body);
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> actualizarPlanta(
    int plantaId, String nombre, String? rutaFotoPerfil,
  ) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$BASE_URL/api/plantas/$plantaId'));
      request.fields['nombre'] = nombre;
      if (rutaFotoPerfil != null) {
        request.files.add(await http.MultipartFile.fromPath('foto_perfil', rutaFotoPerfil));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return json.decode(response.body);
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> eliminarPlanta(int plantaId) async {
    try {
      final response = await http.delete(Uri.parse('$BASE_URL/api/plantas/$plantaId'));
      return json.decode(response.body);
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> actualizarNotificacionesPlanta(int plantaId, bool activas) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/api/plantas/$plantaId/notificaciones'),
        body: {'activas': activas.toString()},
      );
      return json.decode(response.body);
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  // ─── Escaneos de plantas ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> escanearPlanta(
    int plantaId, String rutaImagen, bool esFotoSeguimiento,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST', Uri.parse('$BASE_URL/api/plantas/$plantaId/escanear'),
      );
      request.files.add(await http.MultipartFile.fromPath('imagen', rutaImagen));
      request.fields['es_foto_seguimiento'] = esFotoSeguimiento.toString();
      var streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      var response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'exito': data['exito'] ?? false,
          'tipo_objeto': data['tipo_objeto'] ?? 'hoja_orquidea',
          'resultado': data['resultado'],
          'confianza': data['confianza'] != null
              ? (data['confianza'] is int
                  ? (data['confianza'] as int).toDouble()
                  : (data['confianza'] as num).toDouble())
              : 0.0,
          'instrucciones': data['instrucciones'],
          'paso_numero': data['paso_numero'] ?? 0,
          'escaneo_id': data['escaneo_id'],
          'titulo_paso': data['titulo_paso'],
          'mensaje_especial': data['mensaje_especial'],
          'mensaje': data['mensaje'],
        };
      }
      return {'exito': false, 'mensaje': data['detail'] ?? data['mensaje'] ?? 'Error al analizar'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error de conexión: ${e.toString()}'};
    }
  }

  Future<List<EscaneoPLanta>> obtenerHistorialPlanta(int plantaId) async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/api/plantas/$plantaId/historial'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['escaneos'] as List).map((e) => EscaneoPLanta.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> marcarTratamientoCompletado(int escaneoId) async {
    try {
      final response = await http.put(Uri.parse('$BASE_URL/api/escaneos/$escaneoId/completar'));
      return json.decode(response.body);
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  // ─── Administración ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerTodosUsuarios() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/api/admin/usuarios'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'exito': true, 'usuarios': data['usuarios']};
      }
      return {'exito': false, 'mensaje': 'Error al obtener usuarios'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> eliminarUsuario(int usuarioId) async {
    try {
      final response = await http.delete(Uri.parse('$BASE_URL/api/admin/usuarios/$usuarioId'));
      return json.decode(response.body);
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> cambiarContrasenaUsuario(int usuarioId, String nuevaContrasena) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/api/admin/usuarios/$usuarioId/contrasena'),
        body: {'nueva_contrasena': nuevaContrasena},
      );
      return json.decode(response.body);
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> obtenerHistorialCompleto() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/api/admin/historial-completo'));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'exito': false, 'mensaje': 'Error al obtener historial'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> eliminarRegistroHistorial(int escaneoId) async {
    try {
      final response = await http.delete(Uri.parse('$BASE_URL/api/admin/historial/$escaneoId'));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'exito': false, 'mensaje': 'Error al eliminar registro'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> limpiarHistorialCompleto() async {
    try {
      final response = await http.delete(Uri.parse('$BASE_URL/api/admin/historial/limpiar-todo'));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'exito': false, 'mensaje': 'Error al limpiar historial'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error: ${e.toString()}'};
    }
  }
}
