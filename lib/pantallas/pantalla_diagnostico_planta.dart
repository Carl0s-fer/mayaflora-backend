import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../modelos/planta.dart';
import '../servicios/servicio_api.dart';
import '../servicios/servicio_notificaciones.dart';

class PantallaDiagnosticoPlanta extends StatefulWidget {
  final Usuario usuario;
  final Planta planta;
  final bool esFotoSeguimiento;

  const PantallaDiagnosticoPlanta({
    Key? key,
    required this.usuario,
    required this.planta,
    this.esFotoSeguimiento = false,
  }) : super(key: key);

  @override
  State<PantallaDiagnosticoPlanta> createState() => _PantallaDiagnosticoPlantaState();
}

class _PantallaDiagnosticoPlantaState extends State<PantallaDiagnosticoPlanta> {
  final ServicioApi _api = ServicioApi();
  final ServicioNotificaciones _notif = ServicioNotificaciones();
  final ImagePicker _picker = ImagePicker();

  File? _imagenSeleccionada;
  bool _analizando = false;
  Map<String, dynamic>? _resultadoAnalisis;
  bool _notificacionesActivas = false;
  String? _mensajeError;

  Future<void> _tomarFoto(ImageSource fuente) async {
    final foto = await _picker.pickImage(
      source: fuente,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (foto != null) {
      setState(() {
        _imagenSeleccionada = File(foto.path);
        _resultadoAnalisis = null;
        _mensajeError = null;
      });
    }
  }

  Future<void> _analizarImagen() async {
    if (_imagenSeleccionada == null) return;

    setState(() {
      _analizando = true;
      _resultadoAnalisis = null;
      _mensajeError = null;
    });

    final resultado = await _api.escanearPlanta(
      widget.planta.id,
      _imagenSeleccionada!.path,
      widget.esFotoSeguimiento,
    );

    if (!mounted) return;

    setState(() => _analizando = false);

    final tipoObjeto = resultado['tipo_objeto'] ?? 'hoja_orquidea';

    if (tipoObjeto == 'no_hoja') {
      setState(() => _mensajeError =
          'No se detectó ninguna hoja de orquídea. Por favor tome una foto de una hoja de orquídea.');
      return;
    }

    if (tipoObjeto == 'hoja_otra') {
      setState(() => _mensajeError =
          'No se aprecia bien la hoja de orquídea. Acérquese más a la hoja y tome una foto más clara.');
      return;
    }

    if (resultado['exito'] == true) {
      setState(() => _resultadoAnalisis = resultado);
    } else {
      setState(() => _mensajeError = resultado['mensaje'] ?? 'Error al analizar la imagen');
    }
  }

  Future<void> _guardarYSalir() async {
    if (_resultadoAnalisis == null) return;

    final esEnferma = _resultadoAnalisis!['resultado'] == 'Enferma';

    if (esEnferma && _notificacionesActivas) {
      await _api.actualizarNotificacionesPlanta(widget.planta.id, true);
      await _notif.programarRecordatorioTratamiento(
        plantaId: widget.planta.id,
        nombrePlanta: widget.planta.nombre,
        instrucciones: _resultadoAnalisis!['instrucciones'] ?? '',
        diasEspera: 3,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresMayaflora.fondo,
      appBar: AppBar(
        title: Text(widget.esFotoSeguimiento ? 'Foto de seguimiento' : 'Diagnóstico'),
        backgroundColor: ColoresMayaflora.primario,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_florist, color: ColoresMayaflora.primario, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.planta.nombre,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          widget.esFotoSeguimiento
                              ? 'Foto para evaluar el progreso del tratamiento'
                              : 'Tome una foto para diagnosticar su planta',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Área de imagen
            GestureDetector(
              onTap: _resultadoAnalisis == null && !_analizando
                  ? () => _mostrarOpcionesFoto()
                  : null,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _resultadoAnalisis != null
                        ? (_resultadoAnalisis!['resultado'] == 'Sana'
                            ? ColoresMayaflora.exito
                            : ColoresMayaflora.error)
                        : ColoresMayaflora.secundario.withOpacity(0.5),
                    width: _resultadoAnalisis != null ? 3 : 1,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: _imagenSeleccionada != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt,
                              size: 60, color: ColoresMayaflora.secundario.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text('Toque para tomar una foto',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('Asegúrese de enfocar una hoja de orquídea',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
              ),
            ),

            // Mensaje de error de detección
            if (_mensajeError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_mensajeError!,
                          style: const TextStyle(color: Colors.orange, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _mostrarOpcionesFoto,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ColoresMayaflora.primario),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.camera_alt, color: ColoresMayaflora.primario),
                label: const Text('Tomar nueva foto',
                    style: TextStyle(color: ColoresMayaflora.primario)),
              ),
            ],

            // Botones de acción (antes del análisis)
            if (_imagenSeleccionada != null && _resultadoAnalisis == null && _mensajeError == null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _analizando ? null : _mostrarOpcionesFoto,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ColoresMayaflora.secundario),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.refresh, color: ColoresMayaflora.secundario),
                      label: const Text('Cambiar', style: TextStyle(color: ColoresMayaflora.secundario)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _analizando ? null : _analizarImagen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColoresMayaflora.primario,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _analizando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      label: Text(
                        _analizando ? 'Analizando...' : 'Analizar',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Resultado del análisis
            if (_resultadoAnalisis != null) ...[
              const SizedBox(height: 16),
              _TarjetaResultado(
                resultado: _resultadoAnalisis!,
                notificacionesActivas: _notificacionesActivas,
                onToggleNotificaciones: (val) => setState(() => _notificacionesActivas = val),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _guardarYSalir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _resultadoAnalisis!['resultado'] == 'Sana'
                      ? ColoresMayaflora.exito
                      : ColoresMayaflora.primario,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Entendido, guardar',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Cómo desea tomar la foto?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ColoresMayaflora.primario,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Usar cámara'),
                subtitle: const Text('Tome una foto en este momento'),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ColoresMayaflora.secundario,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Elegir de la galería'),
                subtitle: const Text('Seleccione una foto existente'),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaResultado extends StatelessWidget {
  final Map<String, dynamic> resultado;
  final bool notificacionesActivas;
  final ValueChanged<bool> onToggleNotificaciones;

  const _TarjetaResultado({
    required this.resultado,
    required this.notificacionesActivas,
    required this.onToggleNotificaciones,
  });

  bool get _estaSana => resultado['resultado'] == 'Sana';
  Color get _color => _estaSana ? ColoresMayaflora.exito : ColoresMayaflora.error;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color, width: 2),
        boxShadow: [BoxShadow(color: _color.withOpacity(0.15), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              children: [
                Icon(
                  _estaSana ? Icons.favorite : Icons.healing,
                  color: _color,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  _estaSana ? '¡Planta Sana!' : 'Planta Necesita Atención',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(resultado['confianza'] as num).toStringAsFixed(0)}% de confianza',
                  style: TextStyle(color: _color.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resultado['mensaje_especial'] != null) ...[
                  Text(
                    resultado['mensaje_especial'],
                    style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!_estaSana && resultado['titulo_paso'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medical_services, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                resultado['titulo_paso'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          resultado['instrucciones'] ?? '',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Activar notificaciones
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColoresMayaflora.acento.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColoresMayaflora.acento.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: ColoresMayaflora.acento, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Activar recordatorio de tratamiento',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        ),
                        Switch(
                          value: notificacionesActivas,
                          onChanged: onToggleNotificaciones,
                          activeColor: ColoresMayaflora.primario,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
