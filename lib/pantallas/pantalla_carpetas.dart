import 'package:flutter/material.dart';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../modelos/carpeta.dart';
import '../servicios/servicio_api.dart';
import 'pantalla_plantas_carpeta.dart';

class PantallaCarpetas extends StatefulWidget {
  final Usuario usuario;
  const PantallaCarpetas({Key? key, required this.usuario}) : super(key: key);

  @override
  State<PantallaCarpetas> createState() => _PantallaCarpetasState();
}

class _PantallaCarpetasState extends State<PantallaCarpetas> {
  final ServicioApi _api = ServicioApi();
  List<Carpeta> _carpetas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCarpetas();
  }

  Future<void> _cargarCarpetas() async {
    setState(() => _cargando = true);
    final carpetas = await _api.obtenerCarpetas(widget.usuario.id);
    if (mounted) setState(() { _carpetas = carpetas; _cargando = false; });
  }

  void _mostrarDialogoCarpeta({Carpeta? carpeta}) {
    final controller = TextEditingController(text: carpeta?.nombre ?? '');
    final esEdicion = carpeta != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(esEdicion ? Icons.edit : Icons.create_new_folder,
                color: ColoresMayaflora.primario),
            const SizedBox(width: 8),
            Text(esEdicion ? 'Editar carpeta' : 'Nueva carpeta'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Nombre de la carpeta',
            hintText: 'Ej: Patio delantero',
            prefixIcon: const Icon(Icons.folder),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColoresMayaflora.primario),
            onPressed: () async {
              final nombre = controller.text.trim();
              if (nombre.isEmpty) return;
              Navigator.pop(ctx);
              if (esEdicion) {
                await _api.actualizarCarpeta(carpeta.id, nombre);
              } else {
                await _api.crearCarpeta(widget.usuario.id, nombre);
              }
              _cargarCarpetas();
            },
            child: Text(esEdicion ? 'Guardar' : 'Crear',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCarpeta(Carpeta carpeta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar carpeta'),
        content: Text(
          'Se eliminará "${carpeta.nombre}" y todas las plantas dentro. ¿Está seguro?',
        ),
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
      await _api.eliminarCarpeta(carpeta.id);
      _cargarCarpetas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Plantas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCarpetas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _carpetas.isEmpty
              ? _EmptyState(onCrear: () => _mostrarDialogoCarpeta())
              : RefreshIndicator(
                  onRefresh: _cargarCarpetas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _carpetas.length,
                    itemBuilder: (context, index) {
                      final carpeta = _carpetas[index];
                      return _TarjetaCarpeta(
                        carpeta: carpeta,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PantallaPlantasCarpeta(
                                usuario: widget.usuario,
                                carpeta: carpeta,
                              ),
                            ),
                          );
                          _cargarCarpetas();
                        },
                        onEditar: () => _mostrarDialogoCarpeta(carpeta: carpeta),
                        onEliminar: () => _eliminarCarpeta(carpeta),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCarpeta(),
        backgroundColor: ColoresMayaflora.primario,
        icon: const Icon(Icons.create_new_folder, color: Colors.white),
        label: const Text('Nueva Carpeta', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _TarjetaCarpeta extends StatelessWidget {
  final Carpeta carpeta;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaCarpeta({
    required this.carpeta,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ColoresMayaflora.primario.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder, color: ColoresMayaflora.primario, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(carpeta.nombre,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${carpeta.totalPlantas} ${carpeta.totalPlantas == 1 ? 'planta' : 'plantas'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'editar') onEditar();
                  if (val == 'eliminar') onEliminar();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar',
                      child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Editar')])),
                  const PopupMenuItem(value: 'eliminar',
                      child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Eliminar')])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyState({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No tiene carpetas aún',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Cree carpetas para organizar sus plantas\npor ubicación (Ej: Patio delantero, Balcón)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCrear,
              style: ElevatedButton.styleFrom(backgroundColor: ColoresMayaflora.primario),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Crear primera carpeta', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
