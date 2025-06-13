import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';

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

      // Only add extractedText and uploadedFileName if both are non-null
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
}