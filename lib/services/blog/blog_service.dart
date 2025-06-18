import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_project/services/auth/auth_service.dart';
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
    AuthService authService = AuthService();

    final userData = await authService.fetchUserData();

    String? displayName = userData!.displayName;
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: {'ops': delta.toJson()},
        tags: tags,
        category: selectedCategory,
        authorId: displayName,
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
    AuthService authService = AuthService();
    try {
      final collection = FirebaseFirestore.instance.collection('blogs');
      final userData = await authService.fetchUserData();

      String? userRole = userData!.role;

      Query query = collection;

      if (userRole == 'Doctor') {
        print("WHY TF HERE??????");
        query = collection.where('authorId', isEqualTo: userData.displayName);
      }
      print(query.toString());
      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs
          .map((doc) {
            try {
              return Blog.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .where((blog) => blog != null)
          .cast<Blog>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteBlog(String blogId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('blogs').doc(blogId).delete();

      AppNotifier.show(
        context,
        'Blog deleted successfully!',
        type: MessageType.success,
      );
    } catch (e) {
      AppNotifier.show(
        context,
        'Error deleting blog: ${e.toString()}',
        type: MessageType.error,
      );
    }
  }
}
