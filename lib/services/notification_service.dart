import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/event_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    print('✅ Notification service initialized');
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // You can add navigation logic here
  }

  // Request permissions (especially for iOS)
  Future<bool> requestPermissions() async {
    if (_notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>() != null) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()!
              .requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
          false;
    } else if (_notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>() != null) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()!
              .requestNotificationsPermission() ??
          false;
    }
    return false;
  }

  // Schedule event reminder
  Future<void> scheduleEventReminder({
    required String eventId,
    required EventModel event,
    required int minutesBefore,
  }) async {
    if (!_initialized) await initialize();

    // Calculate notification time
    final notificationTime = event.startAt.subtract(
      Duration(minutes: minutesBefore),
    );

    // Don't schedule if time has passed
    if (notificationTime.isBefore(DateTime.now())) {
      print('⚠️ Notification time has passed, skipping');
      return;
    }

    // Create notification ID from event ID
    final notificationId = eventId.hashCode;

    const androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Event Reminders',
      channelDescription: 'Reminders for upcoming campus events',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '📅 Upcoming Event: ${event.title}',
      'Starting in $minutesBefore minutes at ${event.location}',
      tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: eventId,
    );

    print('✅ Reminder scheduled for ${event.title} at $notificationTime');
  }

  // Cancel event reminder
  Future<void> cancelEventReminder(String eventId) async {
    final notificationId = eventId.hashCode;
    await _notifications.cancel(notificationId);
    print('❌ Reminder cancelled for event: $eventId');
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Event Reminders',
      channelDescription: 'Reminders for upcoming campus events',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('❌ All notifications cancelled');
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}