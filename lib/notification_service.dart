// ─────────────────────────────────────────────────────────────────────────────
//  NotificationService — flutter_local_notifications wrapper
//  Handles initialization, permission requests, and daily scheduled alarms
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialize the notification plugin & timezone data ──────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone setup
    tz.initializeTimeZones();
    final String timeZoneName =
      (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
      AndroidInitializationSettings('@drawable/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap — no-op for now
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    _initialized = true;
  }

  // ── Request Android 13+ POST_NOTIFICATIONS permission ──────────────────

  Future<bool> requestPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final granted =
        await androidPlugin.requestNotificationsPermission() ?? false;
    return granted;
  }

  // ── Request SCHEDULE_EXACT_ALARM (Android 14+) ─────────────────────────

  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final granted =
        await androidPlugin.requestExactAlarmsPermission() ?? false;
    return granted;
  }

  // ── Schedule a daily repeating notification at a specific time ─────────

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_quests',
      'Daily Quests',
      channelDescription: 'Scheduled quest reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '⚔️ DAILY QUEST',
      title,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel a specific notification ─────────────────────────────────────

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  // ── Cancel all notifications ───────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
