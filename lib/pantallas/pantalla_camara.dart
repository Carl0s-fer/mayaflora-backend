import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_api.dart';
import 'pantalla_resultado.dart';

class PantallaCamara extends StatefulWidget {
  final Usuario usuario;

  const PantallaCamara({Key? key, required this.usuario}) : super(key: key);

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

class _PantallaCamaraState extends State<PantallaCamara> {
  final ImagePicker _picker = ImagePicker();
  File? _imagenSeleccionada;
  bool _analizando = false;
  final ServicioApi _servicioApi = ServicioApi();

  Future<void> _tomarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (foto != null) {
        setState(() {
          _imagenSeleccionada = File(foto.path);
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al acceder a la cámara: ${e.toString()}', esError: true);
    }
  }

  Future<void> _seleccionarDeGaleria() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = File(imagen.path);
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al acceder a la galería: ${e.toString()}', esError: true);
    }
  }

  Future<void> _analizarImagen() async {
    if (_imagenSeleccionada == null) {
      _mostrarMensaje('Por favor selecciona una imagen primero', esError: true);
      return;
    }

    setState(() => _analizando = true);

    final resultado = await _servicioApi.analizarImagen(
      _imagenSeleccionada!.path,
      widget.usuario.id,
      widget.usuario.nombreUsuario,
    );

    setState(() => _analizando = false);

    if (resultado['exito']) {
      // Navegar a pantalla de resultado
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaResultado(
              usuario: widget.usuario,
              resultado: resultado['resultado'],
              confianza: resultado['confianza'],
              mensaje: resultado['mensaje'],
              imagenPath: _imagenSeleccionada!.path,
            ),
          ),
        );
      }
    } else {
      _mostrarMensaje(resultado['mensaje'], esError: true);
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? ColoresMayaflora.error : ColoresMayaflora.exito,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomar Fotografía'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EspaciadosMayaflora.grande),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instrucciones
              Container(
                padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
                decoration: BoxDecoration(
                  color: ColoresMayaflora.secundario.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColoresMayaflora.secundario.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: ColoresMayaflora.primario,
                    ),
                    const SizedBox(width: EspaciadosMayaflora.mediano),
                    Expanded(
                      child: Text(
                        'Toma una foto clara de las hojas de la orquídea para detectar hongos',
                        style: EstilosMayaflora.cuerpo.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Vista previa de la imagen
              Expanded(
                child: _imagenSeleccionada == null
                    ? Container(
                        decoration: BoxDecoration(
                          color: ColoresMayaflora.fondo,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ColoresMayaflora.textoSecundario.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera,
                              size: 80,
                              color: ColoresMayaflora.textoSecundario.withOpacity(0.5),
                            ),
                            const SizedBox(height: EspaciadosMayaflora.mediano),
                            Text(
                              'No hay imagen seleccionada',
                              style: EstilosMayaflora.cuerpo.copyWith(
                                color: ColoresMayaflora.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _imagenSeleccionada!,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _analizando ? null : _tomarFoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cámara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresMayaflora.primario,
                        foregroundColor: ColoresMayaflora.blanco,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: EspaciadosMayaflora.mediano),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _analizando ? null : _seleccionarDeGaleria,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresMayaflora.secundario,
                        foregroundColor: ColoresMayaflora.blanco,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspaciadosMayaflora.mediano),

              // Botón de analizar
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_analizando || _imagenSeleccionada == null)
                      ? null
                      : _analizarImagen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresMayaflora.acento,
                    foregroundColor: ColoresMayaflora.texto,
                    disabledBackgroundColor: ColoresMayaflora.textoSecundario,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _analizando
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(width: EspaciadosMayaflora.mediano),
                            Text(
                              'Analizando...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Analizar Imagen',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}