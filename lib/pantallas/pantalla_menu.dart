import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import '../servicios/servicio_api.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_camara.dart';
import 'pantalla_historial.dart';
import 'pantalla_admin_usuarios.dart';
import 'pantalla_carpetas.dart';

class PantallaMenu extends StatelessWidget {
  final Usuario usuario;

  const PantallaMenu({Key? key, required this.usuario}) : super(key: key);

  Future<void> _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaInicioSesion()),
      );
    }
  }

  void _mostrarDialogoCrearUsuario(BuildContext context) {
    final nuevoUsuarioCtrl = TextEditingController();
    final nuevaContrasenaCtrl = TextEditingController();
    final confirmarCtrl = TextEditingController();
    final api = ServicioApi();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: ColoresMayaflora.primario),
            const SizedBox(width: EspaciadosMayaflora.pequeno),
            const Text('Crear Nuevo Usuario'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nuevoUsuarioCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.mediano),
              TextField(
                controller: nuevaContrasenaCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.mediano),
              TextField(
                controller: confirmarCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nuevoUsuarioCtrl.text.isEmpty || nuevaContrasenaCtrl.text.isEmpty || confirmarCtrl.text.isEmpty) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Por favor completa todos los campos'),
                  backgroundColor: ColoresMayaflora.error,
                ));
                return;
              }
              if (nuevaContrasenaCtrl.text != confirmarCtrl.text) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Las contraseñas no coinciden'),
                  backgroundColor: ColoresMayaflora.error,
                ));
                return;
              }
              if (nuevaContrasenaCtrl.text.length < 4) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('La contraseña debe tener al menos 4 caracteres'),
                  backgroundColor: ColoresMayaflora.error,
                ));
                return;
              }
              Navigator.pop(dialogContext);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              final resultado = await api.registro(nuevoUsuarioCtrl.text, nuevaContrasenaCtrl.text);
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(resultado['exito']
                      ? 'Usuario creado exitosamente'
                      : '${resultado["mensaje"]}'),
                  backgroundColor: resultado['exito'] ? ColoresMayaflora.exito : ColoresMayaflora.error,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColoresMayaflora.primario),
            child: const Text('Crear Usuario', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mayaflora Detector'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: Padding(
              padding: const EdgeInsets.all(EspaciadosMayaflora.grande),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${usuario.nombreUsuario}!',
                    style: EstilosMayaflora.titulo,
                  ),
                  const SizedBox(height: EspaciadosMayaflora.pequeno),
                  Text(
                    'Selecciona una opción para continuar',
                    style: EstilosMayaflora.cuerpo.copyWith(
                      color: ColoresMayaflora.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: EspaciadosMayaflora.extraGrande),

                  // Mis Plantas - opción principal y nueva
                  _OpcionMenu(
                    icono: Icons.local_florist,
                    titulo: 'Mis Plantas',
                    descripcion: 'Carpetas y perfiles de tus orquídeas',
                    color: const Color(0xFF1B5E20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaCarpetas(usuario: usuario),
                        ),
                      );
                    },
                    esDestacado: true,
                  ),
                  const SizedBox(height: EspaciadosMayaflora.mediano),

                  _OpcionMenu(
                    icono: Icons.camera_alt,
                    titulo: 'Análisis Rápido',
                    descripcion: 'Escanear una hoja sin guardar perfil',
                    color: ColoresMayaflora.primario,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaCamara(usuario: usuario),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: EspaciadosMayaflora.mediano),

                  _OpcionMenu(
                    icono: Icons.history,
                    titulo: 'Historial General',
                    descripcion: 'Consultas de análisis anteriores',
                    color: ColoresMayaflora.secundario,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaHistorial(usuario: usuario),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: EspaciadosMayaflora.mediano),

                  if (usuario.nombreUsuario.toLowerCase() == 'admin') ...[
                    _OpcionMenu(
                      icono: Icons.admin_panel_settings,
                      titulo: 'Gestionar Usuarios',
                      descripcion: 'Ver, editar y eliminar usuarios',
                      color: ColoresMayaflora.acento,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PantallaAdminUsuarios(usuario: usuario),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: EspaciadosMayaflora.mediano),
                    _OpcionMenu(
                      icono: Icons.add_circle,
                      titulo: 'Crear Usuario',
                      descripcion: 'Registrar nuevo usuario',
                      color: ColoresMayaflora.secundario,
                      onTap: () => _mostrarDialogoCrearUsuario(context),
                    ),
                    const SizedBox(height: EspaciadosMayaflora.mediano),
                  ],

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
                        const Icon(Icons.info_outline, color: ColoresMayaflora.primario),
                        const SizedBox(width: EspaciadosMayaflora.mediano),
                        Expanded(
                          child: Text(
                            'Mayaflora Detector v2.0\nDetección de enfermedades en orquídeas con seguimiento personalizado',
                            style: EstilosMayaflora.cuerpo.copyWith(
                              fontSize: 12,
                              color: ColoresMayaflora.textoSecundario,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;
  final bool esDestacado;

  const _OpcionMenu({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
    this.esDestacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(EspaciadosMayaflora.grande),
        decoration: BoxDecoration(
          color: esDestacado ? color.withOpacity(0.08) : ColoresMayaflora.blanco,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(esDestacado ? 0.6 : 0.3),
            width: esDestacado ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 36, color: color),
            ),
            const SizedBox(width: EspaciadosMayaflora.mediano),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: EstilosMayaflora.subtitulo),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: EstilosMayaflora.cuerpo.copyWith(
                      fontSize: 13,
                      color: ColoresMayaflora.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
