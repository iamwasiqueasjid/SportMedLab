import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String contentType;
  final String content;
  final String? contentUrl;
  final String? youtubeUrl; // New field for YouTube URL
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
    this.youtubeUrl,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Lesson(
      id: id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      contentType: data['contentType'] ?? '',
      content: data['content'] ?? '',
      contentUrl: data['contentUrl'],
      youtubeUrl: data['youtubeUrl'], // New field
      order: data['order'] ?? 0,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'contentType': contentType,
      'content': content,
      'contentUrl': contentUrl ?? '',
      'youtubeUrl': youtubeUrl ?? '', // New field
      'order': order,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
