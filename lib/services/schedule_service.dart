import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'schedules';

  // Create schedule
  Future<Map<String, dynamic>> createSchedule(ScheduleModel schedule) async {
    try {
      await _firestore.collection(_collectionName).add(schedule.toMap());
      return {
        'success': true,
        'message': 'Schedule created successfully',
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
      String scheduleId, ScheduleModel schedule) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(scheduleId)
          .update(schedule.toMap());
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
      await _firestore.collection(_collectionName).doc(scheduleId).delete();
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

  // Get schedules by filter (major, batch, class, and optional concentration)
  Stream<List<ScheduleModel>> getSchedulesByFilter(
    String major,
    String batch,
    String classCode,
    String? concentration,
  ) {
    Query query = _firestore
        .collection(_collectionName)
        .where('major', isEqualTo: major)
        .where('batch', isEqualTo: batch)
        .where('class', isEqualTo: classCode);

    // Filter by concentration if specified
    if (concentration != null && concentration.isNotEmpty) {
      query = query.where('concentration', isEqualTo: concentration);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  // ADDED: Get schedules by class (backward compatibility)
  Stream<List<ScheduleModel>> getSchedulesByClass(
    String major,
    String classCode,
  ) {
    return _firestore
        .collection(_collectionName)
        .where('major', isEqualTo: major)
        .where('class', isEqualTo: classCode)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get schedules for a specific user (based on their profile)
  Stream<List<ScheduleModel>> getSchedulesForUser(
    String major,
    String batch,
    String classCode,
    String? concentration,
  ) {
    return getSchedulesByFilter(major, batch, classCode, concentration);
  }

  // ADDED: Get today's schedules
  Future<List<ScheduleModel>> getTodaySchedules(
    String major,
    String classCode, {
    String? batch,
    String? concentration,
  }) async {
    try {
      final today = DateTime.now();
      final dayName = _getDayName(today.weekday);

      Query query = _firestore
          .collection(_collectionName)
          .where('major', isEqualTo: major)
          .where('class', isEqualTo: classCode)
          .where('day_of_week', isEqualTo: dayName);

      // Add batch filter if provided
      if (batch != null) {
        query = query.where('batch', isEqualTo: batch);
      }

      // Add concentration filter if provided
      if (concentration != null && concentration.isNotEmpty) {
        query = query.where('concentration', isEqualTo: concentration);
      }

      final snapshot = await query.get();
      final schedules = snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();

      // Sort by start time
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));

      return schedules;
    } catch (e) {
      print('Error getting today schedules: $e');
      return [];
    }
  }

  // Helper: Get day name from weekday number
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // Get all schedules (for admin)
  Stream<List<ScheduleModel>> getAllSchedules() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get schedule by ID
  Future<ScheduleModel?> getSchedule(String scheduleId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(scheduleId).get();
      if (doc.exists) {
        return ScheduleModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting schedule: $e');
      return null;
    }
  }
}
