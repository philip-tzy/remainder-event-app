import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String? id;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime startAt;
  final DateTime endAt;
  final String createdBy;
  final DateTime? createdAt;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.startAt,
    required this.endAt,
    required this.createdBy,
    this.createdAt,
  });

  // Convert EventModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'start_at': Timestamp.fromDate(startAt),
      'end_at': Timestamp.fromDate(endAt),
      'created_by': createdBy,
      'created_at': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // Create EventModel from Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      startAt: (data['start_at'] as Timestamp).toDate(),
      endAt: (data['end_at'] as Timestamp).toDate(),
      createdBy: data['created_by'] ?? '',
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : null,
    );
  }

  // Copy with method for easy updates
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? startAt,
    DateTime? endAt,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}