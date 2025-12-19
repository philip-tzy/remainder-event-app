import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'schedules';

  CollectionReference get _schedulesCollection =>
      _firestore.collection(_collectionName);

  // Create new schedule
  Future<Map<String, dynamic>> createSchedule(ScheduleModel schedule) async {
    try {
      // Check for conflicts (same major, class, day, time)
      final existing = await _schedulesCollection
          .where('major', isEqualTo: schedule.major)
          .where('class', isEqualTo: schedule.classCode)
          .where('day_of_week', isEqualTo: schedule.dayOfWeek)
          .where('time_slot', isEqualTo: schedule.timeSlot)
          .get();

      if (existing.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Schedule conflict: This time slot is already occupied',
        };
      }

      DocumentReference docRef =
          await _schedulesCollection.add(schedule.toMap());

      return {
        'success': true,
        'message': 'Schedule created successfully',
        'scheduleId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create schedule: $e',
      };
    }
  }

  // Update schedule
  Future<Map<String, dynamic>> updateSchedule(
    String scheduleId,
    ScheduleModel schedule,
  ) async {
    try {
      await _schedulesCollection.doc(scheduleId).update(schedule.toMap());

      return {
        'success': true,
        'message': 'Schedule updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update schedule: $e',
      };
    }
  }

  // Delete schedule
  Future<Map<String, dynamic>> deleteSchedule(String scheduleId) async {
    try {
      await _schedulesCollection.doc(scheduleId).delete();

      return {
        'success': true,
        'message': 'Schedule deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete schedule: $e',
      };
    }
  }

  // DIPERBAIKI: Get all schedules (untuk admin statistics)
  Stream<List<ScheduleModel>> getAllSchedules() {
    return _schedulesCollection
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get schedules by major and class (for students)
  Stream<List<ScheduleModel>> getSchedulesByClass(
    String major,
    String classCode,
  ) {
    return _schedulesCollection
        .where('major', isEqualTo: major)
        .where('class', isEqualTo: classCode)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get schedules by day for students
  Stream<List<ScheduleModel>> getSchedulesByDay(
    String major,
    String classCode,
    String dayOfWeek,
  ) {
    return _schedulesCollection
        .where('major', isEqualTo: major)
        .where('class', isEqualTo: classCode)
        .where('day_of_week', isEqualTo: dayOfWeek)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get today's schedules for a student
  Future<List<ScheduleModel>> getTodaySchedules(
    String major,
    String classCode,
  ) async {
    try {
      // Get current day of week
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
      final dayOfWeek = dayNames[now.weekday - 1];

      final snapshot = await _schedulesCollection
          .where('major', isEqualTo: major)
          .where('class', isEqualTo: classCode)
          .where('day_of_week', isEqualTo: dayOfWeek)
          .get();

      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting today schedules: $e');
      return [];
    }
  }

  // Get upcoming classes for notifications
  Future<List<ScheduleModel>> getUpcomingClasses(
    String major,
    String classCode,
  ) async {
    try {
      final todaySchedules = await getTodaySchedules(major, classCode);
      final now = DateTime.now();

      // Filter schedules that are coming up within next 2 hours
      return todaySchedules.where((schedule) {
        final startTime = schedule.getStartTime();
        final twoHoursFromNow = now.add(const Duration(hours: 2));
        return startTime.isAfter(now) && startTime.isBefore(twoHoursFromNow);
      }).toList();
    } catch (e) {
      print('Error getting upcoming classes: $e');
      return [];
    }
  }
}
