import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' or 'user'
  final String? major; // Jurusan
  final String? batch; // Angkatan (2020, 2021, etc.)
  final String? concentration; // Peminatan (optional)
  final String? classCode; // Kelas (1, 2, 3, etc.)
  final String? photoURL; // TAMBAHKAN INI
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.major,
    this.batch,
    this.concentration,
    this.classCode,
    this.photoURL, // TAMBAHKAN INI
    this.createdAt,
  });

  // Get full class name
  String get fullClassName {
    if (classCode == null) return '-';
    return 'Class $classCode';
  }

  // Get full student info
  String get fullStudentInfo {
    if (role != 'user') return 'Admin';
    return '$major - Batch $batch - Class $classCode${concentration != null ? " - $concentration" : ""}';
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'major': major,
      'batch': batch,
      'concentration': concentration,
      'class': classCode,
      'photo_url': photoURL, // TAMBAHKAN INI
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      major: data['major'],
      batch: data['batch'],
      concentration: data['concentration'],
      classCode: data['class'],
      photoURL: data['photo_url'], // TAMBAHKAN INI
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? major,
    String? batch,
    String? concentration,
    String? classCode,
    String? photoURL, // TAMBAHKAN INI
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      major: major ?? this.major,
      batch: batch ?? this.batch,
      concentration: concentration ?? this.concentration,
      classCode: classCode ?? this.classCode,
      photoURL: photoURL ?? this.photoURL, // TAMBAHKAN INI
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
