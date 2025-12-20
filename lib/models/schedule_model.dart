import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String? id;
  final String major;
  final String batch; // Angkatan
  final String? concentration; // Peminatan (optional)
  final String classCode;
  final String dayOfWeek;
  final String subject;
  final String lecturer;
  final String room;
  final String startTime;
  final String endTime;
  final DateTime? createdAt;
  final String createdBy;

  ScheduleModel({
    this.id,
    required this.major,
    required this.batch,
    this.concentration,
    required this.classCode,
    required this.dayOfWeek,
    required this.subject,
    required this.lecturer,
    required this.room,
    required this.startTime,
    required this.endTime,
    this.createdAt,
    required this.createdBy,
  });

  // Get formatted time slot for display
  String get timeSlot => '$startTime - $endTime';

  // Get full class identifier
  String get classIdentifier {
    String base = '$major - Batch $batch - Class $classCode';
    if (concentration != null && concentration!.isNotEmpty) {
      base += ' - $concentration';
    }
    return base;
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'major': major,
      'batch': batch,
      'concentration': concentration,
      'class': classCode,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'subject': subject,
      'lecturer': lecturer,
      'room': room,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'created_by': createdBy,
    };
  }

  // Create from Firestore document
  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Support legacy time_slot format
    String startTime = data['start_time'] ?? '';
    String endTime = data['end_time'] ?? '';
    
    if (startTime.isEmpty && data['time_slot'] != null) {
      final parts = (data['time_slot'] as String).split(' - ');
      if (parts.length == 2) {
        startTime = parts[0].trim();
        endTime = parts[1].trim();
      }
    }
    
    return ScheduleModel(
      id: doc.id,
      major: data['major'] ?? '',
      batch: data['batch'] ?? '',
      concentration: data['concentration'],
      classCode: data['class'] ?? '',
      dayOfWeek: data['day_of_week'] ?? '',
      startTime: startTime,
      endTime: endTime,
      subject: data['subject'] ?? '',
      lecturer: data['lecturer'] ?? '',
      room: data['room'] ?? '',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : null,
      createdBy: data['created_by'] ?? '',
    );
  }

  // Get full display text
  String get fullDisplay => '$subject ($timeSlot)';

  // Copy with method
  ScheduleModel copyWith({
    String? id,
    String? major,
    String? batch,
    String? concentration,
    String? classCode,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? subject,
    String? lecturer,
    String? room,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      major: major ?? this.major,
      batch: batch ?? this.batch,
      concentration: concentration ?? this.concentration,
      classCode: classCode ?? this.classCode,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      lecturer: lecturer ?? this.lecturer,
      room: room ?? this.room,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Parse start time to DateTime
  DateTime getStartTime() {
    final now = DateTime.now();
    final parts = startTime.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  // Get end time
  DateTime getEndTime() {
    final now = DateTime.now();
    final parts = endTime.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  // Check if schedule is happening now
  bool isHappeningNow() {
    final now = DateTime.now();
    final start = getStartTime();
    final end = getEndTime();
    return now.isAfter(start) && now.isBefore(end);
  }

  // Check if schedule is upcoming (within next hour)
  bool isUpcomingSoon() {
    final now = DateTime.now();
    final start = getStartTime();
    final oneHourFromNow = now.add(const Duration(hours: 1));
    return start.isAfter(now) && start.isBefore(oneHourFromNow);
  }
}
