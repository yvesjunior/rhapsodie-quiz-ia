import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutterquiz/core/config/config.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for scheduling local reminder notifications
/// for daily contest when user hasn't played yet.
///
/// This works independently of FCM - no server/internet required.
class LocalReminderService {
  LocalReminderService._();
  static final LocalReminderService instance = LocalReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification IDs for daily contest reminders
  // Format: base + (day * 10) + hour_index
  static const int _reminderBaseId = 1000;

  /// Reminder times (hour of day in 24h format)
  static const List<int> _reminderHours = [10, 14, 18, 20];

  /// Number of days ahead to schedule reminders
  /// This ensures users get reminders even if they don't open the app
  static const int _daysAhead = 7;

  /// Initialize the service (call once on app start)
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    log('LocalReminderService initialized', name: 'LocalReminder');
  }

  void _onNotificationTapped(NotificationResponse response) {
    log(
      'Local reminder tapped: ${response.payload}',
      name: 'LocalReminder',
    );
    // The app will open - daily contest check happens on home screen
  }

  /// Schedule daily contest reminders for multiple days ahead
  /// Call this when:
  /// - App starts and user hasn't completed today's contest
  /// - After midnight (new day)
  /// 
  /// Schedules reminders for the next 7 days so users get notified
  /// even if they don't open the app for a few days.
  Future<void> scheduleContestReminders() async {
    if (!_isInitialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    log(
      'Scheduling contest reminders for $_daysAhead days starting ${now.toIso8601String()}',
      name: 'LocalReminder',
    );

    // Cancel any existing reminders first
    await cancelContestReminders();

    int scheduledCount = 0;

    // Schedule for today and next N days
    for (var dayOffset = 0; dayOffset < _daysAhead; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));

      for (var hourIndex = 0; hourIndex < _reminderHours.length; hourIndex++) {
        final hour = _reminderHours[hourIndex];

        // Unique ID for each day/hour combination
        final id = _reminderBaseId + (dayOffset * 10) + hourIndex;

        // Calculate scheduled time
        final scheduledTime = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          0, // minute
          0, // second
        );

        // Skip if time has already passed
        if (scheduledTime.isBefore(now)) {
          continue;
        }

        await _scheduleReminder(id, scheduledTime, dayOffset);
        scheduledCount++;
      }
    }

    log(
      'Scheduled $scheduledCount reminders for the next $_daysAhead days',
      name: 'LocalReminder',
    );
  }

  Future<void> _scheduleReminder(
    int id,
    tz.TZDateTime scheduledTime,
    int dayOffset,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_contest_reminders',
      'Daily Contest Reminders',
      channelDescription: 'Reminders to complete your daily Rhapsody quiz',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Vary the message based on time of day
    final (title, body) = _getReminderMessage(scheduledTime.hour, dayOffset);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'daily_contest_reminder',
      );
      log(
        'Scheduled reminder #$id for day+$dayOffset at ${scheduledTime.hour}:00',
        name: 'LocalReminder',
      );
    } catch (e) {
      log('Failed to schedule reminder: $e', name: 'LocalReminder');
    }
  }

  /// Get reminder message based on time of day and days since last open
  (String title, String body) _getReminderMessage(int hour, int dayOffset) {
    // For future days, use a "we miss you" style message
    if (dayOffset >= 2) {
      return (
        '📖 We Miss You!',
        "It's been a while! Your daily Rhapsody quiz is waiting. Come back and keep your streak going!",
      );
    }

    if (dayOffset == 1) {
      // Yesterday's reminders didn't work, be more urgent
      return (
        '🔔 New Daily Quiz Available!',
        "A fresh Rhapsody quiz is ready for you today. Don't miss out on ranking points!",
      );
    }

    // Today's reminders - vary by time
    switch (hour) {
      case 10:
        return (
          '☀️ Good Morning!',
          "Your daily Rhapsody quiz is waiting. Start your day with God's Word!",
        );
      case 14:
        return (
          '🎯 Afternoon Reminder',
          "Haven't completed today's quiz yet? Take a quick break with Rhapsody!",
        );
      case 18:
        return (
          '🌅 Evening Check-in',
          "Don't miss today's Rhapsody quiz! Complete it before the day ends.",
        );
      case 20:
        return (
          '🌙 Last Chance Today!',
          "Only a few hours left to complete today's daily Rhapsody quiz!",
        );
      default:
        return (
          '📖 Daily Rhapsody Reminder',
          'Complete your daily quiz to earn ranking points!',
        );
    }
  }

  /// Cancel all contest reminders (for all scheduled days)
  /// Call this when:
  /// - User completes today's contest
  /// - User logs out
  Future<void> cancelContestReminders() async {
    if (!_isInitialized) await init();

    // Cancel all reminders for all days ahead
    for (var dayOffset = 0; dayOffset < _daysAhead; dayOffset++) {
      for (var hourIndex = 0; hourIndex < _reminderHours.length; hourIndex++) {
        final id = _reminderBaseId + (dayOffset * 10) + hourIndex;
        await _plugin.cancel(id);
      }
    }

    log('All contest reminders cancelled (${_daysAhead * _reminderHours.length} notifications)', name: 'LocalReminder');
  }

  /// Check if there are any pending reminders (for debugging)
  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    if (!_isInitialized) await init();
    return _plugin.pendingNotificationRequests();
  }

  /// Show an immediate test notification (for debugging)
  Future<void> showTestNotification() async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'daily_contest_reminders',
      'Daily Contest Reminders',
      channelDescription: 'Reminders to complete your daily Rhapsody quiz',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      999,
      '🧪 Test Local Reminder',
      'This is a test notification from LocalReminderService',
      details,
      payload: 'test',
    );
  }
}

