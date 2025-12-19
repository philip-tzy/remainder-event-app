import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String? id;
  final String major;
  final String classCode;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String timeSlot; // "08:00 - 09:40"
  final String subject; // Mata kuliah
  final String lecturer; // Dosen
  final String room; // Ruangan
  final DateTime? createdAt;
  final String createdBy; // Admin user ID

  ScheduleModel({
    this.id,
    required this.major,
    required this.classCode,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.subject,
    required this.lecturer,
    required this.room,
    this.createdAt,
    required this.createdBy,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'major': major,
      'class': classCode,
      'day_of_week': dayOfWeek,
      'time_slot': timeSlot,
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
    
    return ScheduleModel(
      id: doc.id,
      major: data['major'] ?? '',
      classCode: data['class'] ?? '',
      dayOfWeek: data['day_of_week'] ?? '',
      timeSlot: data['time_slot'] ?? '',
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
  
  // Get class identifier
  String get classIdentifier => '$major - $classCode';

  // Copy with method
  ScheduleModel copyWith({
    String? id,
    String? major,
    String? classCode,
    String? dayOfWeek,
    String? timeSlot,
    String? subject,
    String? lecturer,
    String? room,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      major: major ?? this.major,
      classCode: classCode ?? this.classCode,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      subject: subject ?? this.subject,
      lecturer: lecturer ?? this.lecturer,
      room: room ?? this.room,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Parse time from time slot (e.g., "08:00 - 09:40" -> DateTime for today at 08:00)
  DateTime getStartTime() {
    final now = DateTime.now();
    final startTimeStr = timeSlot.split(' - ')[0];
    final parts = startTimeStr.split(':');
    
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
    final endTimeStr = timeSlot.split(' - ')[1];
    final parts = endTimeStr.split(':');
    
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