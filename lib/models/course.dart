import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final String tutorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> enrolledStudents;
  final List<String> subjects;
  final int enrolledCount;

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.tutorId,
    this.createdAt,
    this.updatedAt,
    this.enrolledStudents = const [],
    this.subjects = const [],
    this.enrolledCount = 0,
  });

  // Create Course from Firestore data
  factory Course.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null; // Handle unexpected types
    }

    return Course(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverImageUrl: data['coverImageUrl'],
      tutorId: data['tutorId'] ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
      subjects: List<String>.from(data['subjects'] ?? []),
      enrolledCount: data['enrolledCount'] ?? 0,
    );
  }

  // Convert Course to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl ?? '',
      'tutorId': tutorId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'enrolledStudents': enrolledStudents,
      'subjects': subjects,
      'enrolledCount': enrolledCount,
    };
  }
}
