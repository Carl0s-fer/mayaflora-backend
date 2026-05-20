import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilidades/constantes.dart';
import '../servicios/servicio_api.dart';
import '../modelos/usuario.dart';
import 'pantalla_menu.dart';

class PantallaInicioSesion extends StatefulWidget {
  const PantallaInicioSesion({Key? key}) : super(key: key);

  @override
  State<PantallaInicioSesion> createState() => _PantallaInicioSesionState();
}

class _PantallaInicioSesionState extends State<PantallaInicioSesion> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final ServicioApi _servicioApi = ServicioApi();
  bool _cargando = false;
  bool _mostrarContrasena = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_usuarioController.text.isEmpty || _contrasenaController.text.isEmpty) {
      _mostrarMensaje(MensajesMayaflora.camposVacios, esError: true);
      return;
    }

    setState(() => _cargando = true);

    final resultado = await _servicioApi.login(
      _usuarioController.text,
      _contrasenaController.text,
    );

    setState(() => _cargando = false);

    if (resultado['exito']) {
      Usuario usuario = resultado['usuario'];
      
      // Guardar usuario en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usuario_id', usuario.id);
      await prefs.setString('nombre_usuario', usuario.nombreUsuario);

      // Navegar al menú
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaMenu(usuario: usuario),
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

  void _mostrarDialogoRegistro() {
    final TextEditingController nuevoUsuarioController = TextEditingController();
    final TextEditingController nuevaContrasenaController = TextEditingController();
    final TextEditingController confirmarContrasenaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Cuenta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nuevoUsuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.mediano),
              TextField(
                controller: nuevaContrasenaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.mediano),
              TextField(
                controller: confirmarContrasenaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nuevoUsuarioController.text.isEmpty ||
                  nuevaContrasenaController.text.isEmpty ||
                  confirmarContrasenaController.text.isEmpty) {
                Navigator.pop(context);
                _mostrarMensaje('Por favor completa todos los campos', esError: true);
                return;
              }

              if (nuevaContrasenaController.text != confirmarContrasenaController.text) {
                Navigator.pop(context);
                _mostrarMensaje('Las contraseñas no coinciden', esError: true);
                return;
              }

              if (nuevaContrasenaController.text.length < 4) {
                Navigator.pop(context);
                _mostrarMensaje('La contraseña debe tener al menos 4 caracteres', esError: true);
                return;
              }

              Navigator.pop(context);

              setState(() => _cargando = true);

              final resultado = await _servicioApi.registro(
                nuevoUsuarioController.text,
                nuevaContrasenaController.text,
              );

              setState(() => _cargando = false);

              if (resultado['exito']) {
                _mostrarMensaje('¡Cuenta creada exitosamente! Ahora puedes iniciar sesión');
                _usuarioController.text = nuevoUsuarioController.text;
              } else {
                _mostrarMensaje(resultado['mensaje'], esError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColoresMayaflora.primario,
            ),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresMayaflora.fondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EspaciadosMayaflora.grande),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o ícono
                Icon(
                  Icons.local_florist,
                  size: 100,
                  color: ColoresMayaflora.primario,
                ),
                const SizedBox(height: EspaciadosMayaflora.grande),
                
                // Título
                Text(
                  MensajesMayaflora.bienvenida,
                  style: EstilosMayaflora.titulo,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: EspaciadosMayaflora.pequeno),
                
                // Descripción
                Text(
                  MensajesMayaflora.descripcion,
                  style: EstilosMayaflora.cuerpo.copyWith(
                    color: ColoresMayaflora.textoSecundario,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: EspaciadosMayaflora.extraGrande),
                
                // Campo de usuario
                TextField(
                  controller: _usuarioController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: ColoresMayaflora.blanco,
                  ),
                ),
                const SizedBox(height: EspaciadosMayaflora.mediano),
                
                // Campo de contraseña
                TextField(
                  controller: _contrasenaController,
                  obscureText: !_mostrarContrasena,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarContrasena ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _mostrarContrasena = !_mostrarContrasena);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: ColoresMayaflora.blanco,
                  ),
                ),
                const SizedBox(height: EspaciadosMayaflora.grande),
                
                // Botón de iniciar sesión
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresMayaflora.primario,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Iniciar Sesión',
                            style: EstilosMayaflora.boton,
                          ),
                  ),
                ),
                const SizedBox(height: EspaciadosMayaflora.grande),
              ],
            ),
          ),
        ),
      ),
    );
  }
}