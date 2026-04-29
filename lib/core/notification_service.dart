import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract final class NotificationService {
  static const _dailyBaseId = 100; // IDs 100–109
  static const _inactivityId = 200;
  static const _batchDays = 10;

  static const _messages = [
    'A forja não para. Mais um dia.',
    'Ferro se torna aço na resistência.',
    'Você escolheu ser forte hoje.',
    'Cada dia é um golpe de martelo.',
    'A disciplina constrói o que a vontade promete.',
    'Não existe atalho. Só o processo.',
    'Sua força está sendo forjada agora.',
    'O fraco cede. O forte continua.',
    'Um dia de cada vez. Sem falhar.',
    'A brasa não apaga. Alimente o fogo.',
    'Resistência é o único caminho.',
    'Hoje você prova quem você é.',
  ];

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _iosDetails = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    ),
  );

  // ── Inicialização ─────────────────────────────────────────────────

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Mantém UTC como fallback se timezone não for detectado
    }

    await _plugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  // ── Permissão ─────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        ) ??
        false;
  }

  // ── Agendamento ───────────────────────────────────────────────────

  static Future<void> scheduleAll() async {
    await _scheduleDailyMotivational();
    await _scheduleInactivityAlert();
  }

  static Future<void> _scheduleDailyMotivational() async {
    // Cancela lote anterior antes de reagendar
    for (var i = 0; i < _batchDays; i++) {
      await _plugin.cancel(_dailyBaseId + i);
    }

    final now = tz.TZDateTime.now(tz.local);

    for (var day = 1; day <= _batchDays; day++) {
      final scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        8, // 08:00
        0,
        0,
      ).add(Duration(days: day));

      final msg = _messages[(now.day + day) % _messages.length];

      await _plugin.zonedSchedule(
        _dailyBaseId + day - 1,
        'Forja',
        msg,
        scheduled,
        _iosDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> _scheduleInactivityAlert() async {
    await _plugin.cancel(_inactivityId);

    // Reagenda sempre que o app abre — se o usuário não abrir por 2 dias, dispara
    final scheduled =
        tz.TZDateTime.now(tz.local).add(const Duration(days: 2));

    await _plugin.zonedSchedule(
      _inactivityId,
      'Forja',
      'Sua espada está esfriando. Volte à forja.',
      scheduled,
      _iosDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
