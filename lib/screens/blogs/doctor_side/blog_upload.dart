import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/models/blog.dart';
import 'package:test_project/services/blog/file_processor.dart';
import 'package:test_project/services/blog/blog_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import '../../../services/blog/content_formatter.dart';
import '../../../services/blog/metadata_service.dart';
import 'blog_upload_widgets.dart';
import 'blog_preview.dart';

class AdvancedBlogEditorWidget extends StatefulWidget {
  const AdvancedBlogEditorWidget({super.key});

  @override
  State<AdvancedBlogEditorWidget> createState() =>
      _AdvancedBlogEditorWidgetState();
}

class _AdvancedBlogEditorWidgetState extends State<AdvancedBlogEditorWidget> {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String? _selectedCategory;
  final List<String> _suggestedTags = [];
  bool _isProcessingFile = false;
  bool _isGeneratingTags = false;
  bool _isPublishing = false;
  String? _extractedText;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _uploadFile() async {
    setState(() => _isProcessingFile = true);
    try {
      final result = await FileProcessor.uploadFile();
      if (result != null) {
        setState(() {
          _uploadedFileName = result['fileName'];
          _extractedText = result['extractedText'];
        });
        await ContentFormatter.processExtractedContent(
          _controller,
          result['extractedText'],
          result['structure'],
          (bool isGenerating) =>
              setState(() => _isGeneratingTags = isGenerating),
        );
        await MetadataService.generateMetadataWithAI(
          context,
          result['extractedText'],
          _titleController,
          _tagsController,
          _suggestedTags,
          (String? category) => setState(() => _selectedCategory = category),
        );
        AppNotifier.show(
          context,
          'File processed successfully! Content added to editor with formatting.',
          type: MessageType.success,
        );
      }
    } catch (e) {
      AppNotifier.show(
        context,
        'Error processing file: ${e.toString()}',
        type: MessageType.error,
      );
    } finally {
      setState(() => _isProcessingFile = false);
    }
  }

  void _previewBlog() {
    if (_titleController.text.trim().isEmpty) {
      AppNotifier.show(
        context,
        'Please enter a title before previewing.',
        type: MessageType.error,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlogPreviewPopup(
              title: _titleController.text.trim(),
              controller: _controller,
              tags:
                  _tagsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
              category: _selectedCategory ?? BlogConstants.defaultCategory,
            ),
      ),
    );
  }

  Future<void> _publishBlog() async {
    setState(() => _isPublishing = true);
    try {
      await BlogService.publishBlog(
        context,
        _titleController,
        _controller,
        _tagsController,
        _selectedCategory,
        _extractedText,
        _uploadedFileName,
      );
      _clearForm();
    } catch (e) {
      AppNotifier.show(
        context,
        'Error publishing blog: ${e.toString()}',
        type: MessageType.error,
      );
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _tagsController.clear();
    setState(() {
      _controller.clear();
      _selectedCategory = null;
      _suggestedTags.clear();
      _extractedText = null;
      _uploadedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      color: Colors.blue[600],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blog Editor',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create and publish engaging blog content',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                ],
              ),
            ),

            const SizedBox(height: 20),

            // File Upload Section
            _buildSection(
              title: 'Document Upload',
              icon: Icons.upload_file,
              child: BlogUploadWidgets.buildFileUploadSection(
                context,
                _uploadedFileName,
                _isProcessingFile,
                _uploadFile,
              ),
            ),
            
            const SizedBox(height: 20),

            // Blog Details Section
            _buildSection(
              title: 'Blog Details',
              icon: Icons.article,
              child: Column(
                children: [
                  BlogUploadWidgets.buildTitleInput(context, _titleController),
                  const SizedBox(height: 10),
                  BlogUploadWidgets.buildCategorySelector(
                    context,
                    _selectedCategory,
                    (String? value) =>
                        setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: 10),
                  BlogUploadWidgets.buildTagsInput(
                    context,
                    _tagsController,
                    _suggestedTags,
                    _isGeneratingTags,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content Editor Section
            _buildSection(
              title: 'Content Editor',
              icon: Icons.edit,
              child: BlogUploadWidgets.buildQuillEditor(context, _controller),
            ),

            const SizedBox(height: 15),

            // Action Buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _previewBlog,
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text(
                      'Preview Blog',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.blue[600]!, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
backgroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.clear, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isPublishing ? null : _publishBlog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isPublishing
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: SpinKitDoubleBounce(
                                    color: Color(0xFF0A2D7B),
                                    size: 40.0,
                                  ),
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.publish, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Publish Blog',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[700], size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
// Divider
          Container(
            height: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: child,
          ),
        ],
      ),
    );
  }
}
