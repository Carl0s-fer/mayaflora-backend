import 'package:flutter/material.dart';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_api.dart';

class PantallaAdminUsuarios extends StatefulWidget {
  final Usuario usuario;

  const PantallaAdminUsuarios({Key? key, required this.usuario}) : super(key: key);

  @override
  State<PantallaAdminUsuarios> createState() => _PantallaAdminUsuariosState();
}

class _PantallaAdminUsuariosState extends State<PantallaAdminUsuarios> {
  final ServicioApi _servicioApi = ServicioApi();
  List<dynamic> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    final resultado = await _servicioApi.obtenerTodosUsuarios();
    if (resultado['exito']) {
      setState(() {
        _usuarios = resultado['usuarios'];
        _cargando = false;
      });
    } else {
      setState(() => _cargando = false);
      _mostrarMensaje(resultado['mensaje'], esError: true);
    }
  }

  void _mostrarDialogoEliminar(dynamic usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar a ${usuario['nombre_usuario']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final resultado = await _servicioApi.eliminarUsuario(usuario['id']);
              _mostrarMensaje(resultado['mensaje'], esError: !resultado['exito']);
              if (resultado['exito']) _cargarUsuarios();
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColoresMayaflora.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCambiarContrasena(dynamic usuario) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Contraseña - ${usuario['nombre_usuario']}'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nueva Contraseña',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 4) {
                _mostrarMensaje('Mínimo 4 caracteres', esError: true);
                return;
              }
              Navigator.pop(context);
              final resultado = await _servicioApi.cambiarContrasenaUsuario(
                usuario['id'],
                controller.text,
              );
              _mostrarMensaje(resultado['mensaje'], esError: !resultado['exito']);
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? ColoresMayaflora.error : ColoresMayaflora.exito,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Usuarios'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarUsuarios,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = _usuarios[index];
                  final esAdmin = usuario['nombre_usuario'].toLowerCase() == 'admin';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: esAdmin ? ColoresMayaflora.acento : ColoresMayaflora.primario,
                        child: Icon(
                          esAdmin ? Icons.admin_panel_settings : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        usuario['nombre_usuario'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${usuario['total_escaneos']} escaneos'),
                      trailing: esAdmin
                          ? const Chip(
                              label: Text('ADMIN', style: TextStyle(fontSize: 10)),
                              backgroundColor: ColoresMayaflora.acento,
                            )
                          : PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'password',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock),
                                      SizedBox(width: 8),
                                      Text('Cambiar Contraseña'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _mostrarDialogoEliminar(usuario);
                                } else if (value == 'password') {
                                  _mostrarDialogoCambiarContrasena(usuario);
                                }
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}