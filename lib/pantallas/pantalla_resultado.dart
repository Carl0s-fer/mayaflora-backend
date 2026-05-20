import 'package:flutter/material.dart';
import 'dart:io';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import 'pantalla_menu.dart';
import 'pantalla_tratamiento.dart';

class PantallaResultado extends StatelessWidget {
  final Usuario usuario;
  final String resultado;
  final double confianza;
  final String mensaje;
  final String imagenPath;

  const PantallaResultado({
    Key? key,
    required this.usuario,
    required this.resultado,
    required this.confianza,
    required this.mensaje,
    required this.imagenPath,
  }) : super(key: key);

  bool get estaEnferma => resultado.toLowerCase() == 'enferma';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del Análisis'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspaciadosMayaflora.grande),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen analizada
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagenPath),
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Card de resultado
              Container(
                padding: const EdgeInsets.all(EspaciadosMayaflora.grande),
                decoration: BoxDecoration(
                  color: estaEnferma
                      ? ColoresMayaflora.error.withOpacity(0.1)
                      : ColoresMayaflora.exito.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: estaEnferma
                        ? ColoresMayaflora.error
                        : ColoresMayaflora.exito,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Ícono de resultado
                    Container(
                      padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
                      decoration: BoxDecoration(
                        color: estaEnferma
                            ? ColoresMayaflora.error
                            : ColoresMayaflora.exito,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        estaEnferma ? Icons.warning : Icons.check_circle,
                        size: 60,
                        color: ColoresMayaflora.blanco,
                      ),
                    ),
                    const SizedBox(height: EspaciadosMayaflora.mediano),

                    // Título del resultado
                    Text(
                      estaEnferma ? '¡Orquídea Enferma!' : '¡Orquídea Sana!',
                      style: EstilosMayaflora.titulo.copyWith(
                        color: estaEnferma
                            ? ColoresMayaflora.error
                            : ColoresMayaflora.exito,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: EspaciadosMayaflora.pequeno),

                    // Mensaje
                    Text(
                      mensaje,
                      style: EstilosMayaflora.cuerpo,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: EspaciadosMayaflora.mediano),

                    // Barra de confianza
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nivel de confianza:',
                              style: EstilosMayaflora.cuerpo.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${confianza.toStringAsFixed(1)}%',
                              style: EstilosMayaflora.cuerpo.copyWith(
                                fontWeight: FontWeight.bold,
                                color: estaEnferma
                                    ? ColoresMayaflora.error
                                    : ColoresMayaflora.exito,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: EspaciadosMayaflora.pequeno),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: confianza / 100,
                            backgroundColor: ColoresMayaflora.textoSecundario.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              estaEnferma
                                  ? ColoresMayaflora.error
                                  : ColoresMayaflora.exito,
                            ),
                            minHeight: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Información adicional
              if (estaEnferma)
                Container(
                  padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
                  decoration: BoxDecoration(
                    color: ColoresMayaflora.acento.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColoresMayaflora.acento.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: ColoresMayaflora.acento,
                      ),
                      const SizedBox(width: EspaciadosMayaflora.mediano),
                      Expanded(
                        child: Text(
                          'Se ha detectado la presencia de hongos en las hojas. Revisa el tratamiento recomendado.',
                          style: EstilosMayaflora.cuerpo.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Botones de acción
              if (estaEnferma) ...[
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaTratamiento(usuario: usuario),
                        ),
                      );
                    },
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Ver Tratamiento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColoresMayaflora.acento,
                      foregroundColor: ColoresMayaflora.texto,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: EspaciadosMayaflora.mediano),
              ],

              // Botón volver al menú
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PantallaMenu(usuario: usuario),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al Menú'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColoresMayaflora.primario,
                    side: const BorderSide(
                      color: ColoresMayaflora.primario,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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