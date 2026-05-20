import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../modelos/carpeta.dart';
import '../modelos/planta.dart';
import '../servicios/servicio_api.dart';
import 'pantalla_detalle_planta.dart';

class PantallaPlantasCarpeta extends StatefulWidget {
  final Usuario usuario;
  final Carpeta carpeta;

  const PantallaPlantasCarpeta({
    Key? key,
    required this.usuario,
    required this.carpeta,
  }) : super(key: key);

  @override
  State<PantallaPlantasCarpeta> createState() => _PantallaPlantasCarpetaState();
}

class _PantallaPlantasCarpetaState extends State<PantallaPlantasCarpeta> {
  final ServicioApi _api = ServicioApi();
  final ImagePicker _picker = ImagePicker();
  List<Planta> _plantas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPlantas();
  }

  Future<void> _cargarPlantas() async {
    setState(() => _cargando = true);
    final plantas = await _api.obtenerPlantas(widget.carpeta.id);
    if (mounted) setState(() { _plantas = plantas; _cargando = false; });
  }

  Future<String?> _seleccionarFoto() async {
    final fuente = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Foto de perfil'),
        content: const Text('¿Cómo desea agregar la foto de la planta?'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          TextButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Sin foto'),
          ),
        ],
      ),
    );
    if (fuente == null) return null;
    final foto = await _picker.pickImage(
      source: fuente,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    return foto?.path;
  }

  void _mostrarDialogoPlanta({Planta? planta}) {
    final controller = TextEditingController(text: planta?.nombre ?? '');
    String? rutaFoto;
    final esEdicion = planta != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(esEdicion ? Icons.edit : Icons.local_florist,
                  color: ColoresMayaflora.primario),
              const SizedBox(width: 8),
              Text(esEdicion ? 'Editar planta' : 'Nueva planta'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final ruta = await _seleccionarFoto();
                    if (ruta != null) setStateDialog(() => rutaFoto = ruta);
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: ColoresMayaflora.secundario.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: ColoresMayaflora.primario, width: 2),
                    ),
                    child: rutaFoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.file(File(rutaFoto!), fit: BoxFit.cover),
                          )
                        : (esEdicion && planta.fotoPerfil != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.memory(
                                  base64Decode(planta.fotoPerfil!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt, color: ColoresMayaflora.primario, size: 28),
                                  SizedBox(height: 4),
                                  Text('Foto', style: TextStyle(fontSize: 11, color: ColoresMayaflora.primario)),
                                ],
                              )),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la planta',
                    hintText: 'Ej: Orquídea blanca',
                    prefixIcon: const Icon(Icons.local_florist),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ColoresMayaflora.primario),
              onPressed: () async {
                final nombre = controller.text.trim();
                if (nombre.isEmpty) return;
                Navigator.pop(ctx);
                _mostrarCargando();
                if (esEdicion) {
                  await _api.actualizarPlanta(planta.id, nombre, rutaFoto);
                } else {
                  await _api.crearPlanta(
                      widget.carpeta.id, widget.usuario.id, nombre, rutaFoto);
                }
                if (mounted) Navigator.pop(context);
                _cargarPlantas();
              },
              child: Text(esEdicion ? 'Guardar' : 'Crear',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCargando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _eliminarPlanta(Planta planta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar planta'),
        content: Text('Se eliminará "${planta.nombre}" y todo su historial. ¿Está seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColoresMayaflora.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _api.eliminarPlanta(planta.id);
      _cargarPlantas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.carpeta.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPlantas,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _plantas.isEmpty
              ? _EmptyStatePlantas(onCrear: () => _mostrarDialogoPlanta())
              : RefreshIndicator(
                  onRefresh: _cargarPlantas,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _plantas.length,
                    itemBuilder: (context, index) {
                      final planta = _plantas[index];
                      return _TarjetaPlanta(
                        planta: planta,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PantallaDetallePlanta(
                                usuario: widget.usuario,
                                planta: planta,
                              ),
                            ),
                          );
                          _cargarPlantas();
                        },
                        onEditar: () => _mostrarDialogoPlanta(planta: planta),
                        onEliminar: () => _eliminarPlanta(planta),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoPlanta(),
        backgroundColor: ColoresMayaflora.primario,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Planta', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _TarjetaPlanta extends StatelessWidget {
  final Planta planta;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaPlanta({
    required this.planta,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  Color get _colorEstado {
    if (planta.estaSana) return ColoresMayaflora.exito;
    if (planta.estaEnferma) return ColoresMayaflora.error;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _colorEstado, width: 2.5),
      ),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: planta.fotoPerfil != null
                        ? Image.memory(
                            base64Decode(planta.fotoPerfil!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: ColoresMayaflora.secundario.withOpacity(0.1),
                            child: const Center(
                              child: Icon(Icons.local_florist,
                                  size: 60, color: ColoresMayaflora.secundario),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'editar') onEditar();
                        if (val == 'eliminar') onEliminar();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'editar',
                            child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 18), SizedBox(width: 8), Text('Editar')])),
                        const PopupMenuItem(value: 'eliminar',
                            child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Eliminar')])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      planta.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _colorEstado.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            planta.estaSana
                                ? Icons.favorite
                                : planta.estaEnferma
                                    ? Icons.healing
                                    : Icons.help_outline,
                            color: _colorEstado,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            planta.estaSana
                                ? 'Sana'
                                : planta.estaEnferma
                                    ? 'Enferma'
                                    : 'Sin diagnóstico',
                            style: TextStyle(
                              fontSize: 11,
                              color: _colorEstado,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (planta.estaEnferma && planta.notificacionesActivas)
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_active,
                                color: ColoresMayaflora.acento, size: 12),
                            SizedBox(width: 3),
                            Text('Recordatorio activo',
                                style: TextStyle(fontSize: 10, color: ColoresMayaflora.acento)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStatePlantas extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyStatePlantas({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No hay plantas en esta carpeta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Agregue perfiles de plantas para hacer seguimiento de su salud',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCrear,
              style: ElevatedButton.styleFrom(backgroundColor: ColoresMayaflora.primario),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Agregar planta', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
