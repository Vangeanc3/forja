import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/entities/settings_entity.dart';

abstract final class NotificationService {
  static const _dailyBaseId = 100; // IDs 100–109
  static const _inactivityId = 200;
  static const _weeklyReportId = 300;
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

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'forja_notifications',
      'Notificações Forja',
      channelDescription: 'Canal principal de notificações do Forja',
      importance: Importance.max,
      priority: Priority.high,
    ),
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
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
    if (kIsWeb) return true; // Web notifications are requested differently or ignored here
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        ) ??
        false;
  }

  // ── Agendamento ───────────────────────────────────────────────────

  static Future<void> scheduleAll(SettingsEntity settings) async {
    if (!settings.notificationsEnabled) {
      await _plugin.cancelAll();
      return;
    }

    await _scheduleDailyMotivational(settings.notificationHour);
    await _scheduleInactivityAlert();
    await _scheduleWeeklyReport();
    await _scheduleRiskAlerts(settings.riskHours);
  }

  static Future<void> _scheduleRiskAlerts(List<String> riskHours) async {
    const riskBaseId = 400; // 400-410

    // Cancela agendamentos anteriores de risco
    for (var i = 0; i < 10; i++) {
      await _plugin.cancel(riskBaseId + i);
    }

    if (riskHours.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    final riskMessages = [
      'Horário de risco. Fique forte.',
      'Sua espada está sendo testada agora.',
      'Esse momento vai passar. Resista.',
    ];

    int idOffset = 0;
    for (final window in riskHours) {
      try {
        final parts = window.split('-');
        final startStr = parts[0];
        final startParts = startStr.split(':');
        final hour = int.parse(startParts[0]);
        final minute = int.parse(startParts[1]);

        for (var day = 0; day < 3; day++) {
          var scheduledDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          ).add(Duration(days: day));

          if (scheduledDate.isBefore(now)) continue;

          await _plugin.zonedSchedule(
            riskBaseId + idOffset++,
            'Forja',
            riskMessages[idOffset % riskMessages.length],
            scheduledDate,
            _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );

          if (idOffset >= 10) break;
        }
      } catch (_) {
        // Ignora janelas mal formatadas
      }
      if (idOffset >= 10) break;
    }
  }

  static Future<void> _scheduleWeeklyReport() async {
    await _plugin.cancel(_weeklyReportId);

    final now = tz.TZDateTime.now(tz.local);
    // Próximo domingo às 20h
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 20:00
      0,
    );

    // Se já passou das 20h de hoje ou não é domingo, move para o próximo domingo
    if (scheduledDate.isBefore(now) ||
        scheduledDate.weekday != DateTime.sunday) {
      final daysUntilSunday = (DateTime.sunday - scheduledDate.weekday + 7) % 7;
      scheduledDate = scheduledDate.add(
        Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday),
      );
    }

    await _plugin.zonedSchedule(
      _weeklyReportId,
      'Forja',
      'Seu relatório semanal está pronto',
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> _scheduleDailyMotivational(int hour) async {
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
        hour, // Usa o horário configurado
        0,
        0,
      ).add(Duration(days: day));

      final msg = _messages[(now.day + day) % _messages.length];

      await _plugin.zonedSchedule(
        _dailyBaseId + day - 1,
        'Forja',
        msg,
        scheduled,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> _scheduleInactivityAlert() async {
    await _plugin.cancel(_inactivityId);

    // Reagenda sempre que o app abre — se o usuário não abrir por 2 dias, dispara
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(days: 2));

    await _plugin.zonedSchedule(
      _inactivityId,
      'Forja',
      'Sua espada está esfriando. Volte à forja.',
      scheduled,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
