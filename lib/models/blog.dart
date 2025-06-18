import 'package:cloud_firestore/cloud_firestore.dart';

class Blog {
  final String id;
  final String title;
  final Map<String, dynamic> content;
  final List<String> tags;
  final String category;
  final String? authorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final int viewCount;
  final int likeCount;
  final String? extractedText;
  final String? sourceFile;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.category,
    this.authorId,
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.extractedText,
    this.sourceFile,
  });

  factory Blog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now(); // Fallback for unexpected types
    }

    Map<String, dynamic> parseContent(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      return {}; // Handle unexpected types
    }

    return Blog(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      content: parseContent(data['content']),
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'] ?? 'Uncategorized',
      authorId: data['authorId'],
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']) ?? DateTime.now(),
      isPublished: data['isPublished'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      extractedText: data['extractedText'],
      sourceFile: data['sourceFile'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'tags': tags,
      'category': category,
      'authorId': authorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPublished': isPublished,
      'viewCount': viewCount,
      'likeCount': likeCount,
      if (extractedText != null) 'extractedText': extractedText,
      if (sourceFile != null) 'sourceFile': sourceFile,
    };
  }
}

class BlogConstants {
  static const String defaultCategory = 'General Medicine';
  static const List<String> categories = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Pediatrics',
    'Surgery',
    'Mental Health',
    'Nutrition',
    'Preventive Care',
    'Emergency Medicine',
  ];
}
