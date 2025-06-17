import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_project/utils/blogs/constants.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/models/blog.dart'; // Add import for Blog model

class BlogService {
  static Future<void> publishBlog(
    context,
    TextEditingController titleController,
    QuillController controller,
    TextEditingController tagsController,
    String? selectedCategory,
    String? extractedText,
    String? uploadedFileName,
  ) async {
    final title = titleController.text.trim();
    final delta = controller.document.toDelta();
    final tags =
        tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    if (title.isEmpty) {
      AppNotifier.show(
        context,
        'Please enter a blog title.',
        type: MessageType.error,
      );
      return;
    }

    if (controller.document.isEmpty()) {
      AppNotifier.show(
        context,
        'Please add content to your blog.',
        type: MessageType.error,
      );
      return;
    }

    if (selectedCategory == null) {
      AppNotifier.show(
        context,
        'Please select a category.',
        type: MessageType.error,
      );
      return;
    }

    try {
      final blog = Blog(
        title: title,
        content: {'ops': delta.toJson()},
        tags: tags,
        category: selectedCategory,
        authorId: AppConstants.currentDoctorId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: true,
        extractedText: extractedText,
        sourceFile: uploadedFileName,
      );

      await FirebaseFirestore.instance
          .collection('blogs')
          .add(blog.toFirestore());

      AppNotifier.show(
        context,
        'Blog published successfully with enhanced formatting!',
        type: MessageType.success,
      );
    } catch (e) {
      AppNotifier.show(
        context,
        'Error publishing blog: ${e.toString()}',
        type: MessageType.error,
      );
    }
  }

  static Future<List<Blog>> getPublishedBlogs() async {
    try {
      final collection = FirebaseFirestore.instance.collection('blogs');
      final querySnapshot =
          await collection
              .where('isPublished', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs
          .map((doc) {
            try {
              return Blog.fromFirestore(doc);
            } catch (e) {
              print('Error parsing blog document ${doc.id}: $e');
              return null;
            }
          })
          .where((blog) => blog != null)
          .cast<Blog>()
          .toList();
    } catch (e) {
      print('Error fetching published blogs: ${e.toString()}');
      return [];
    }
  }
}
