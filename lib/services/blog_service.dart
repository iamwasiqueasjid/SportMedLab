import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/constants.dart';

class BlogService {
  static Future<void> publishBlog(
      TextEditingController titleController,
      QuillController controller,
      TextEditingController tagsController,
      String? selectedCategory,
      String? extractedText,
      String? uploadedFileName,
      Function(String) showErrorSnackBar,
      Function(String) showSuccessSnackBar,
      ) async {
    final title = titleController.text.trim();
    final delta = controller.document.toDelta();
    final tags = tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (title.isEmpty) {
      showErrorSnackBar('Please enter a blog title.');
      return;
    }

    if (controller.document.isEmpty()) {
      showErrorSnackBar('Please add content to your blog.');
      return;
    }

    if (selectedCategory == null) {
      showErrorSnackBar('Please select a category.');
      return;
    }

    try {
      final Map<String, dynamic> blogData = {
        'title': title,
        'content': delta.toJson(),
        'tags': tags,
        'category': selectedCategory,
        'authorId': AppConstants.currentDoctorId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isPublished': true,
        'viewCount': 0,
        'likeCount': 0,
      };

      if (extractedText != null && uploadedFileName != null) {
        blogData['extractedText'] = extractedText;
        blogData['sourceFile'] = uploadedFileName;
      }

      await FirebaseFirestore.instance.collection('blogs').add(blogData);
      showSuccessSnackBar('Blog published successfully with enhanced formatting!');
    } catch (e) {
      showErrorSnackBar('Error publishing blog: ${e.toString()}');
    }
  }

  static Future<List<Map<String, dynamic>>> getPublishedBlogs() async {
    try {
      print('Initiating Firestore connection...');
      final collection = FirebaseFirestore.instance.collection('blogs');
      print('Collection reference obtained: $collection');

      // Temporarily remove filters to test connectivity
      print('Executing query without filters...');
      final querySnapshot = await collection.get();
      print('Query executed. Documents found: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('No documents found in the blogs collection.');
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing document ID: ${doc.id}, Data: $data');
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'content': data['content'] ?? {},
          'tags': (data['tags'] as List?)?.cast<String>() ?? [],
          'category': data['category'] ?? 'Uncategorized',
          'extractedText': data['extractedText'],
          'sourceFile': data['sourceFile'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error in getPublishedBlogs: $e');
      return [];
    }
  }
}