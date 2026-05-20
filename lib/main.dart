import 'package:flutter/material.dart';
import 'pantallas/pantalla_inicio_sesion.dart';
import 'servicios/servicio_notificaciones.dart';
import 'utilidades/constantes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioNotificaciones().inicializar();
  runApp(const MayafloraApp());
}

class MayafloraApp extends StatelessWidget {
  const MayafloraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mayaflora Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: ColoresMayaflora.primario,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColoresMayaflora.primario,
          secondary: ColoresMayaflora.secundario,
        ),
        scaffoldBackgroundColor: ColoresMayaflora.fondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: ColoresMayaflora.primario,
          foregroundColor: ColoresMayaflora.blanco,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const PantallaInicioSesion(),
    );
  }
}
