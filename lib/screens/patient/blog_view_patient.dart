import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class PatientBlogPreviewScreen extends StatelessWidget {
  final String title;
  final QuillController controller;
  final List<String> tags;
  final String category;

  const PatientBlogPreviewScreen({
    super.key,
    required this.title,
    required this.controller,
    required this.tags,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuillEditor(
              controller: controller,
              scrollController: ScrollController(),
              focusNode: FocusNode(),
              // Removed configurations and readOnly due to undefined errors
            ),
            const SizedBox(height: 16),
            Text('Category: $category', style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text('Tags: ${tags.join(', ')}', style: TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to PatientsScreen
              },
              child: const Text('View More Blogs'),
            ),
          ],
        ),
      ),
    );
  }
}