import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' or 'user'
  final String? major; // For students only
  final String? classCode; // For students only (A, B, C, etc)
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.major,
    this.classCode,
    this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'major': major,
      'class': classCode,
      'created_at': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      major: data['major'],
      classCode: data['class'],
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : null,
    );
  }

  // Get display name for class
  String get classDisplay => classCode ?? 'N/A';
  
  // Get full class name (e.g., "Computer Science - A")
  String get fullClassName => major != null && classCode != null 
      ? '$major - $classCode' 
      : 'N/A';

  // Check if user is admin
  bool get isAdmin => role == 'admin';
  
  // Check if user is student
  bool get isStudent => role == 'user';
}