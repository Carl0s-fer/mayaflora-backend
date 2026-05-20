import 'package:flutter/material.dart';
import '../utilidades/constantes.dart';
import '../modelos/usuario.dart';
import 'pantalla_menu.dart';

class PantallaTratamiento extends StatelessWidget {
  final Usuario usuario;

  const PantallaTratamiento({Key? key, required this.usuario}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tratamiento Recomendado'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspaciadosMayaflora.grande),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Text(
                'Tratamiento para Hongos en Hojas de Orquídeas',
                style: EstilosMayaflora.titulo,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Advertencia
              Container(
                padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
                decoration: BoxDecoration(
                  color: ColoresMayaflora.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColoresMayaflora.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: ColoresMayaflora.error,
                    ),
                    const SizedBox(width: EspaciadosMayaflora.mediano),
                    Expanded(
                      child: Text(
                        'Consulta con un especialista en orquídeas para un diagnóstico preciso.',
                        style: EstilosMayaflora.cuerpo.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Pasos del tratamiento
              _PasoTratamiento(
                numero: 1,
                titulo: 'Aislamiento',
                descripcion:
                    'Separa la orquídea afectada de otras plantas para evitar la propagación del hongo.',
                icono: Icons.remove_circle_outline,
              ),
              _PasoTratamiento(
                numero: 2,
                titulo: 'Limpieza',
                descripcion:
                    'Retira cuidadosamente las hojas más afectadas con tijeras esterilizadas. Limpia las hojas restantes con un paño húmedo.',
                icono: Icons.cleaning_services,
              ),
              _PasoTratamiento(
                numero: 3,
                titulo: 'Fungicida',
                descripcion:
                    'Aplica un fungicida específico para orquídeas siguiendo las instrucciones del fabricante. Repite la aplicación según lo indicado.',
                icono: Icons.medical_services,
              ),
              _PasoTratamiento(
                numero: 4,
                titulo: 'Ventilación',
                descripcion:
                    'Mejora la circulación de aire alrededor de la planta. Los hongos prosperan en ambientes húmedos y sin ventilación.',
                icono: Icons.air,
              ),
              _PasoTratamiento(
                numero: 5,
                titulo: 'Control de Humedad',
                descripcion:
                    'Reduce el riego y evita mojar las hojas. Riega solo cuando el sustrato esté casi seco.',
                icono: Icons.water_drop,
              ),
              _PasoTratamiento(
                numero: 6,
                titulo: 'Monitoreo',
                descripcion:
                    'Revisa la planta diariamente durante 2-3 semanas. Si los síntomas persisten, consulta con un especialista.',
                icono: Icons.remove_red_eye,
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Productos recomendados
              Container(
                padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
                decoration: BoxDecoration(
                  color: ColoresMayaflora.secundario.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_pharmacy,
                          color: ColoresMayaflora.primario,
                        ),
                        const SizedBox(width: EspaciadosMayaflora.pequeno),
                        Text(
                          'Productos Recomendados:',
                          style: EstilosMayaflora.subtitulo,
                        ),
                      ],
                    ),
                    const SizedBox(height: EspaciadosMayaflora.mediano),
                    _ProductoRecomendado('Fungicida a base de cobre'),
                    _ProductoRecomendado('Canela en polvo (tratamiento natural)'),
                    _ProductoRecomendado('Alcohol isopropílico (70% para limpieza)'),
                    _ProductoRecomendado('Aceite de neem (preventivo)'),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Prevención
              Container(
                padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
                decoration: BoxDecoration(
                  color: ColoresMayaflora.acento.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield,
                          color: ColoresMayaflora.acento,
                        ),
                        const SizedBox(width: EspaciadosMayaflora.pequeno),
                        Text(
                          'Prevención Futura:',
                          style: EstilosMayaflora.subtitulo,
                        ),
                      ],
                    ),
                    const SizedBox(height: EspaciadosMayaflora.mediano),
                    Text(
                      '• Mantén buena ventilación\n'
                      '• Evita el exceso de humedad\n'
                      '• No mojes las hojas al regar\n'
                      '• Esteriliza herramientas de poda\n'
                      '• Inspecciona regularmente tus plantas',
                      style: EstilosMayaflora.cuerpo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspaciadosMayaflora.grande),

              // Botón volver al menú
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresMayaflora.primario,
                    foregroundColor: ColoresMayaflora.blanco,
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

class _PasoTratamiento extends StatelessWidget {
  final int numero;
  final String titulo;
  final String descripcion;
  final IconData icono;

  const _PasoTratamiento({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: EspaciadosMayaflora.mediano),
      padding: const EdgeInsets.all(EspaciadosMayaflora.mediano),
      decoration: BoxDecoration(
        color: ColoresMayaflora.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColoresMayaflora.primario.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColoresMayaflora.primario,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$numero',
                style: const TextStyle(
                  color: ColoresMayaflora.blanco,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: EspaciadosMayaflora.mediano),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icono,
                      color: ColoresMayaflora.primario,
                      size: 20,
                    ),
                    const SizedBox(width: EspaciadosMayaflora.pequeno),
                    Text(
                      titulo,
                      style: EstilosMayaflora.subtitulo.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: EspaciadosMayaflora.pequeno),
                Text(
                  descripcion,
                  style: EstilosMayaflora.cuerpo.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductoRecomendado extends StatelessWidget {
  final String nombre;

  const _ProductoRecomendado(this.nombre);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspaciadosMayaflora.pequeno),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: ColoresMayaflora.exito,
            size: 20,
          ),
          const SizedBox(width: EspaciadosMayaflora.pequeno),
          Expanded(
            child: Text(
              nombre,
              style: EstilosMayaflora.cuerpo.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}