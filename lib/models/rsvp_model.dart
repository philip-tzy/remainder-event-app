import 'package:cloud_firestore/cloud_firestore.dart';

class RsvpModel {
  final String? id;
  final String eventId;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime? rsvpAt;
  final bool reminderEnabled;
  final int? reminderMinutesBefore; // Minutes before event to remind

  RsvpModel({
    this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.rsvpAt,
    this.reminderEnabled = false,
    this.reminderMinutesBefore,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'rsvp_at': rsvpAt != null 
          ? Timestamp.fromDate(rsvpAt!) 
          : FieldValue.serverTimestamp(),
      'reminder_enabled': reminderEnabled,
      'reminder_minutes_before': reminderMinutesBefore,
    };
  }

  // Create from Firestore document
  factory RsvpModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RsvpModel(
      id: doc.id,
      eventId: data['event_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      userEmail: data['user_email'] ?? '',
      rsvpAt: data['rsvp_at'] != null 
          ? (data['rsvp_at'] as Timestamp).toDate() 
          : null,
      reminderEnabled: data['reminder_enabled'] ?? false,
      reminderMinutesBefore: data['reminder_minutes_before'],
    );
  }

  // Copy with method
  RsvpModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userEmail,
    DateTime? rsvpAt,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
  }) {
    return RsvpModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      rsvpAt: rsvpAt ?? this.rsvpAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }
}