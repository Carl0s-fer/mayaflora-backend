import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../modelos/historial_escaneo.dart';
import '../servicios/servicio_api.dart';

class PantallaHistorial extends StatefulWidget {
  final Usuario usuario;

  const PantallaHistorial({Key? key, required this.usuario}) : super(key: key);

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  final ServicioApi _servicioApi = ServicioApi();
  List<HistorialEscaneo> _historial = [];
  bool _cargando = true;
  String? _error;

  bool get _esAdmin => widget.usuario.nombreUsuario.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final resultado = _esAdmin 
        ? await _servicioApi.obtenerHistorialCompleto()
        : await _servicioApi.obtenerHistorial(widget.usuario.id);

    if (resultado['exito']) {
      final List<dynamic> historialJson = resultado['historial'];
      setState(() {
        _historial = historialJson
            .map((json) => HistorialEscaneo.fromJson(json))
            .toList();
        _cargando = false;
      });
    } else {
      setState(() {
        _error = resultado['mensaje'];
        _cargando = false;
      });
    }
  }

  Future<void> _eliminarRegistro(int escaneoId) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresMayaflora.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Eliminar registro
    final resultado = await _servicioApi.eliminarRegistroHistorial(escaneoId);
    
    if (resultado['exito']) {
      _mostrarMensaje('Registro eliminado correctamente');
      _cargarHistorial(); // Recargar historial
    } else {
      _mostrarMensaje(resultado['mensaje'] ?? 'Error al eliminar', esError: true);
    }
  }

  Future<void> _limpiarHistorialCompleto() async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Advertencia'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar TODO el historial?\n\n'
          'Esta acción NO se puede deshacer y eliminará todos los registros de todos los usuarios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresMayaflora.error,
            ),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Limpiar historial
    final resultado = await _servicioApi.limpiarHistorialCompleto();
    
    if (resultado['exito']) {
      _mostrarMensaje('Historial limpiado completamente');
      _cargarHistorial(); // Recargar historial
    } else {
      _mostrarMensaje(resultado['mensaje'] ?? 'Error al limpiar historial', esError: true);
    }
  }

  Future<void> _compartirHistorial() async {
    if (_historial.isEmpty) {
      _mostrarMensaje('No hay historial para compartir', esError: true);
      return;
    }

    // Formato en una línea separado por guiones
    String texto = 'Historial Mayaflora - ${widget.usuario.nombreUsuario}: ';
    
    List<String> registros = [];
    for (var escaneo in _historial) {
      registros.add('${escaneo.fechaFormateada}, ${escaneo.resultado}, ${escaneo.confianza.toStringAsFixed(1)}%');
    }
    
    texto += registros.join(' - ');

    await Share.share(texto, subject: 'Historial Mayaflora');
  }

  Future<void> _descargarHistorial() async {
    if (_historial.isEmpty) {
      _mostrarMensaje('No hay historial para descargar', esError: true);
      return;
    }

    try {
      // Formato en una línea separado por comas
      String texto = 'Usuario: ${widget.usuario.nombreUsuario}\n';
      texto += 'Historial: ';
      
      List<String> registros = [];
      for (var escaneo in _historial) {
        registros.add('${escaneo.fechaFormateada}, ${escaneo.resultado}, ${escaneo.confianza.toStringAsFixed(1)}%');
      }
      
      texto += registros.join(', ');

      // Guardar en la carpeta de Descargas/Documentos pública
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Para Android, guardar en Descargas (accesible)
        directory = Directory('/storage/emulated/0/Download');
        
        // Si no existe, intentar con Documents
        if (!await directory.exists()) {
          directory = Directory('/storage/emulated/0/Documents');
        }
        
        // Si tampoco existe, usar la carpeta de la app
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        // Para iOS usar Documents de la app
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        _mostrarMensaje('No se pudo acceder a la carpeta de descargas', esError: true);
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/historial_mayaflora_$timestamp.txt');
      await file.writeAsString(texto);

      _mostrarMensaje('✅ Historial guardado en: ${directory.path}');
    } catch (e) {
      _mostrarMensaje('Error al guardar historial: $e', esError: true);
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
        title: Text(_esAdmin 
            ? 'Historial Completo (Todos los Usuarios)' 
            : 'Historial de Escaneos'),
        actions: [
          if (_historial.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _compartirHistorial,
              tooltip: 'Compartir',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _descargarHistorial,
              tooltip: 'Descargar',
            ),
            // Botón para limpiar todo el historial (solo admin)
            if (_esAdmin)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _limpiarHistorialCompleto,
                tooltip: 'Limpiar todo',
                color: ColoresMayaflora.error,
              ),
          ],
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: ColoresMayaflora.error,
                        ),
                        const SizedBox(height: EspaciadosMayaflora.grande),
                        Text(
                          'Error al cargar historial',
                          style: EstilosMayaflora.subtitulo,
                        ),
                        const SizedBox(height: EspaciadosMayaflora.pequeno),
                        Text(
                          _error!,
                          style: EstilosMayaflora.cuerpo.copyWith(
                            color: ColoresMayaflora.textoSecundario,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: EspaciadosMayaflora.grande),
                        ElevatedButton(
                          onPressed: _cargarHistorial,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _historial.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: ColoresMayaflora.textoSecundario.withOpacity(0.5),
                            ),
                            const SizedBox(height: EspaciadosMayaflora.grande),
                            Text(
                              'No hay escaneos registrados',
                              style: EstilosMayaflora.subtitulo,
                            ),
                            const SizedBox(height: EspaciadosMayaflora.pequeno),
                            Text(
                              'Realiza tu primer escaneo para ver el historial',
                              style: EstilosMayaflora.cuerpo.copyWith(
                                color: ColoresMayaflora.textoSecundario,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarHistorial,
                        child: Column(
                          children: [
                            // Resumen estadístico
                            Container(
                              margin: const EdgeInsets.all(EspaciadosMayaflora.mediano),
                              padding: const EdgeInsets.all(EspaciadosMayaflora.grande),
                              decoration: BoxDecoration(
                                color: ColoresMayaflora.primario.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _Estadistica(
                                    icono: Icons.analytics,
                                    titulo: 'Total',
                                    valor: '${_historial.length}',
                                    color: ColoresMayaflora.primario,
                                  ),
                                  _Estadistica(
                                    icono: Icons.check_circle,
                                    titulo: 'Sanas',
                                    valor: '${_historial.where((e) => !e.estaEnferma).length}',
                                    color: ColoresMayaflora.exito,
                                  ),
                                  _Estadistica(
                                    icono: Icons.warning,
                                    titulo: 'Enfermas',
                                    valor: '${_historial.where((e) => e.estaEnferma).length}',
                                    color: ColoresMayaflora.error,
                                  ),
                                ],
                              ),
                            ),

                            // Lista de escaneos
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
                                itemCount: _historial.length,
                                itemBuilder: (context, index) {
                                  final escaneo = _historial[index];
                                  return _TarjetaEscaneo(
                                    escaneo: escaneo,
                                    esAdmin: _esAdmin,
                                    onEliminar: () => _eliminarRegistro(escaneo.id),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}

class _Estadistica extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;

  const _Estadistica({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icono, color: color, size: 32),
        const SizedBox(height: EspaciadosMayaflora.pequeno),
        Text(
          valor,
          style: EstilosMayaflora.titulo.copyWith(
            color: color,
            fontSize: 24,
          ),
        ),
        Text(
          titulo,
          style: EstilosMayaflora.cuerpo.copyWith(
            fontSize: 12,
            color: ColoresMayaflora.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _TarjetaEscaneo extends StatelessWidget {
  final HistorialEscaneo escaneo;
  final bool esAdmin;
  final VoidCallback onEliminar;

  const _TarjetaEscaneo({
    required this.escaneo,
    required this.esAdmin,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final esEnferma = escaneo.estaEnferma;
    final color = esEnferma ? ColoresMayaflora.error : ColoresMayaflora.exito;

    return Container(
      margin: const EdgeInsets.only(bottom: EspaciadosMayaflora.mediano),
      decoration: BoxDecoration(
        color: ColoresMayaflora.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
        child: Row(
          children: [
            // Icono de resultado
            Container(
              padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                esEnferma ? Icons.warning : Icons.check_circle,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: EspaciadosMayaflora.mediano),

            // Información del escaneo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        escaneo.resultado,
                        style: EstilosMayaflora.subtitulo.copyWith(
                          color: color,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: EspaciadosMayaflora.pequeno),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EspaciadosMayaflora.pequeno,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${escaneo.confianza.toStringAsFixed(1)}%',
                          style: EstilosMayaflora.cuerpo.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: ColoresMayaflora.textoSecundario,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        escaneo.nombreUsuario,
                        style: EstilosMayaflora.cuerpo.copyWith(
                          fontSize: 12,
                          color: ColoresMayaflora.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: ColoresMayaflora.textoSecundario,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        escaneo.fechaFormateada,
                        style: EstilosMayaflora.cuerpo.copyWith(
                          fontSize: 12,
                          color: ColoresMayaflora.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Botón de eliminar (solo para admin)
            if (esAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: ColoresMayaflora.error,
                onPressed: onEliminar,
                tooltip: 'Eliminar',
              ),
          ],
        ),
      ),
    );
  }
}