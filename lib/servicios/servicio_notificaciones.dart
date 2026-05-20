import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class ServicioNotificaciones {
  static final ServicioNotificaciones _instancia = ServicioNotificaciones._interno();
  factory ServicioNotificaciones() => _instancia;
  ServicioNotificaciones._interno();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  Future<void> inicializar() async {
    if (_inicializado) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    _inicializado = true;
  }

  Future<bool> solicitarPermisos() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final resultado = await androidPlugin?.requestNotificationsPermission();
    return resultado ?? true;
  }

  Future<void> programarRecordatorioTratamiento({
    required int plantaId,
    required String nombrePlanta,
    required String instrucciones,
    required int diasEspera,
  }) async {
    await _plugin.cancel(plantaId);

    final ahora = tz.TZDateTime.now(tz.local);
    final fechaNotificacion = ahora.add(Duration(days: diasEspera));

    const androidDetails = AndroidNotificationDetails(
      'tratamiento_orquidea',
      'Tratamiento de Orquídeas',
      channelDescription: 'Recordatorios para el tratamiento de sus orquídeas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      plantaId,
      '🌺 Recordatorio: $nombrePlanta',
      'Es momento de continuar el tratamiento de su orquídea. Tome una nueva foto para evaluar su progreso.',
      fechaNotificacion,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> mostrarNotificacionInmediata({
    required String titulo,
    required String cuerpo,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mayaflora_general',
      'Mayaflora General',
      channelDescription: 'Notificaciones generales de Mayaflora',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, titulo, cuerpo, details);
  }

  Future<void> cancelarNotificacion(int plantaId) async {
    await _plugin.cancel(plantaId);
  }

  Future<void> cancelarTodasLasNotificaciones() async {
    await _plugin.cancelAll();
  }
}
