import '../models/schedule_model.dart';
import 'notification_service.dart';

class ScheduleNotificationService {
  static final ScheduleNotificationService _instance =
      ScheduleNotificationService._internal();
  factory ScheduleNotificationService() => _instance;
  ScheduleNotificationService._internal();

  final NotificationService _notificationService = NotificationService();

  // Schedule notification for a class (1 hour before)
  Future<void> scheduleClassNotification(ScheduleModel schedule) async {
    await _notificationService.initialize();

    // Calculate notification time (1 hour before class)
    final classStartTime = schedule.getStartTime();
    final notificationTime = classStartTime.subtract(const Duration(hours: 1));

    // Don't schedule if time has passed
    if (notificationTime.isBefore(DateTime.now())) {
      print('⚠️ Notification time has passed for ${schedule.subject}');
      return;
    }

    // Create unique notification ID from schedule details
    final notificationId = '${schedule.major}_${schedule.classCode}_${schedule.dayOfWeek}_${schedule.timeSlot}'
        .hashCode;

    // Schedule the notification using NotificationService
    await _notificationService.scheduleNotification(
      id: notificationId,
      title: '📚 Upcoming Class: ${schedule.subject}',
      body: 'Class starts at ${schedule.timeSlot.split(' - ')[0]} in ${schedule.room} with ${schedule.lecturer}',
      scheduledTime: notificationTime,
      payload: schedule.id,
    );

    print('✅ Class notification scheduled for ${schedule.subject} at $notificationTime');
  }

  // Schedule all classes for the week
  Future<void> scheduleWeeklyClassNotifications(
    List<ScheduleModel> schedules,
  ) async {
    await _notificationService.initialize();
    
    for (var schedule in schedules) {
      // Get the next occurrence of this class
      final nextClassTime = _getNextOccurrence(schedule);
      if (nextClassTime != null) {
        await scheduleClassNotification(schedule);
      }
    }
  }

  // Get next occurrence of a schedule
  DateTime? _getNextOccurrence(ScheduleModel schedule) {
    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    // Find the day index
    final scheduleDayIndex = dayNames.indexOf(schedule.dayOfWeek);
    if (scheduleDayIndex == -1) return null;

    // Calculate days until next occurrence
    final currentDayIndex = now.weekday - 1;
    int daysUntil = scheduleDayIndex - currentDayIndex;

    if (daysUntil < 0) {
      daysUntil += 7; // Next week
    } else if (daysUntil == 0) {
      // Today - check if time has passed
      final classTime = schedule.getStartTime();
      if (classTime.isBefore(now)) {
        daysUntil = 7; // Next week
      }
    }

    final nextDate = now.add(Duration(days: daysUntil));
    final startTime = schedule.getStartTime();

    return DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      startTime.hour,
      startTime.minute,
    );
  }

  // Cancel all class notifications
  Future<void> cancelAllClassNotifications() async {
    await _notificationService.cancelAllNotifications();
    print('❌ All class notifications cancelled');
  }

  // Test immediate notification
  Future<void> testClassNotification(ScheduleModel schedule) async {
    await _notificationService.showImmediateNotification(
      title: '📚 Test: ${schedule.subject}',
      body: 'Class at ${schedule.timeSlot} in ${schedule.room}',
      payload: schedule.id,
    );
  }
}
