import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String contentType;
  final String content;
  final String? contentUrl;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.contentType,
    required this.content,
    this.contentUrl,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  // Create Lesson from Firestore data
  factory Lesson.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null; // Handle unexpected types
    }

    return Lesson(
      id: id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      contentType: data['contentType'] ?? '',
      content: data['content'] ?? '',
      contentUrl: data['contentUrl'],
      order: data['order'] ?? 0,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  // Convert Lesson to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'contentType': contentType,
      'content': content,
      'contentUrl': contentUrl ?? '',
      'order': order,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
