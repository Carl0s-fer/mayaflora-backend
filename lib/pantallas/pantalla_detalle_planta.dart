import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../modelos/planta.dart';
import '../modelos/escaneo_planta.dart';
import '../servicios/servicio_api.dart';
import '../servicios/servicio_notificaciones.dart';
import 'pantalla_diagnostico_planta.dart';

class PantallaDetallePlanta extends StatefulWidget {
  final Usuario usuario;
  final Planta planta;

  const PantallaDetallePlanta({
    Key? key,
    required this.usuario,
    required this.planta,
  }) : super(key: key);

  @override
  State<PantallaDetallePlanta> createState() => _PantallaDetallePlantaState();
}

class _PantallaDetallePlantaState extends State<PantallaDetallePlanta> {
  final ServicioApi _api = ServicioApi();
  final ServicioNotificaciones _notif = ServicioNotificaciones();

  List<EscaneoPLanta> _escaneos = [];
  bool _cargando = true;
  late Planta _planta;

  @override
  void initState() {
    super.initState();
    _planta = widget.planta;
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _cargando = true);
    final escaneos = await _api.obtenerHistorialPlanta(_planta.id);
    if (mounted) setState(() { _escaneos = escaneos; _cargando = false; });
  }

  Future<void> _toggleNotificaciones(bool value) async {
    await _api.actualizarNotificacionesPlanta(_planta.id, value);
    if (value && _escaneos.isNotEmpty) {
      final ultimo = _escaneos.first;
      if (ultimo.resultado == 'Enferma') {
        await _notif.programarRecordatorioTratamiento(
          plantaId: _planta.id,
          nombrePlanta: _planta.nombre,
          instrucciones: ultimo.instrucciones ?? '',
          diasEspera: 3,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recordatorio programado. Le avisaremos sobre el tratamiento.'),
              backgroundColor: ColoresMayaflora.primario,
            ),
          );
        }
      }
    } else {
      await _notif.cancelarNotificacion(_planta.id);
    }
    setState(() => _planta = Planta(
      id: _planta.id,
      nombre: _planta.nombre,
      fotoPerfil: _planta.fotoPerfil,
      estadoActual: _planta.estadoActual,
      pasoTratamientoActual: _planta.pasoTratamientoActual,
      notificacionesActivas: value,
      fechaCreacion: _planta.fechaCreacion,
      fechaUltimoEscaneo: _planta.fechaUltimoEscaneo,
    ));
  }

  Future<void> _marcarCompletado(EscaneoPLanta escaneo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Completó el tratamiento?'),
        content: const Text(
          'Al confirmar, podrá tomar una nueva foto para evaluar el estado de su planta.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Aún no')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColoresMayaflora.primario),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, completé el paso', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _api.marcarTratamientoCompletado(escaneo.id);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PantallaDiagnosticoPlanta(
              usuario: widget.usuario,
              planta: _planta,
              esFotoSeguimiento: true,
            ),
          ),
        );
        _cargarHistorial();
      }
    }
  }

  void _irADiagnostico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaDiagnosticoPlanta(
          usuario: widget.usuario,
          planta: _planta,
          esFotoSeguimiento: _escaneos.isNotEmpty,
        ),
      ),
    ).then((_) => _cargarHistorial());
  }

  Color get _colorEstado {
    if (_planta.estaSana) return ColoresMayaflora.exito;
    if (_planta.estaEnferma) return ColoresMayaflora.error;
    return Colors.grey;
  }

  String get _textoEstado {
    if (_planta.estaSana) return 'Sana';
    if (_planta.estaEnferma) return 'Necesita atención';
    return 'Sin diagnóstico';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: ColoresMayaflora.primario,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_planta.nombre,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _planta.fotoPerfil != null
                      ? Image.memory(
                          base64Decode(_planta.fotoPerfil!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: ColoresMayaflora.secundario.withOpacity(0.3),
                          child: const Icon(Icons.local_florist,
                              size: 80, color: ColoresMayaflora.primario),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _colorEstado.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _planta.estaSana ? Icons.favorite : _planta.estaEnferma ? Icons.healing : Icons.help_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(_textoEstado,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Acciones principales
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _irADiagnostico,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColoresMayaflora.primario,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: Text(
                            _escaneos.isEmpty ? 'Primer diagnóstico' : 'Nueva foto',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Notificaciones (solo si está enferma)
                  if (_planta.estaEnferma) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: ColoresMayaflora.acento.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ColoresMayaflora.acento.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications, color: ColoresMayaflora.acento),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Recordatorios de tratamiento',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          Switch(
                            value: _planta.notificacionesActivas,
                            onChanged: _toggleNotificaciones,
                            activeColor: ColoresMayaflora.primario,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text('Historial de fotos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (_cargando)
            const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
          else if (_escaneos.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('No hay fotos aún',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Tome la primera foto de diagnóstico',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final escaneo = _escaneos[index];
                  return _TarjetaEscaneo(
                    escaneo: escaneo,
                    onMarcarCompletado: escaneo.resultado == 'Enferma' && !escaneo.tratamientoCompletado
                        ? () => _marcarCompletado(escaneo)
                        : null,
                  );
                },
                childCount: _escaneos.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _TarjetaEscaneo extends StatelessWidget {
  final EscaneoPLanta escaneo;
  final VoidCallback? onMarcarCompletado;

  const _TarjetaEscaneo({required this.escaneo, this.onMarcarCompletado});

  Color get _colorResultado =>
      escaneo.estaSana ? ColoresMayaflora.exito : ColoresMayaflora.error;

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.parse(escaneo.fechaEscaneo);
    final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(fecha);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _colorResultado, width: 2),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del escaneo
          if (escaneo.imagenBase64 != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.memory(
                base64Decode(escaneo.imagenBase64!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _colorResultado.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _colorResultado),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            escaneo.estaSana ? Icons.check_circle : Icons.warning,
                            color: _colorResultado,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            escaneo.estaSana ? 'Sana' : 'Enferma',
                            style: TextStyle(
                              color: _colorResultado,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${escaneo.confianza.toStringAsFixed(0)}% confianza',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Spacer(),
                    Text(fechaFormateada,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),

                if (!escaneo.estaSana && escaneo.pasoNumero > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medical_services_outlined,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 6),
                            Text('Paso ${escaneo.pasoNumero} de tratamiento',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          escaneo.instrucciones ?? '',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],

                if (escaneo.estaSana && escaneo.instrucciones != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColoresMayaflora.exito.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration, color: ColoresMayaflora.exito, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            escaneo.instrucciones!,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (onMarcarCompletado != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onMarcarCompletado,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ColoresMayaflora.primario),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline,
                          color: ColoresMayaflora.primario, size: 18),
                      label: const Text('Completé este paso → Tomar nueva foto',
                          style: TextStyle(color: ColoresMayaflora.primario, fontSize: 13)),
                    ),
                  ),
                ],

                if (escaneo.tratamientoCompletado)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.task_alt, color: Colors.green[600], size: 14),
                        const SizedBox(width: 6),
                        Text('Tratamiento completado',
                            style: TextStyle(color: Colors.green[600], fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
