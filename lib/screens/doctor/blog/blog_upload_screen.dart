import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:test_project/utils/blogs/constants.dart';
import '../../../Services/file_processor.dart';
import '../../../utils/blogs/content_formatter.dart';
import '../../../services/blog/metadata_service.dart';
import '../../../Services/blog_service.dart';
import '../../../utils/blogs/ui_utils.dart'; // Use alias to avoid conflicts
import 'blog_preview_screen.dart';

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
          result['extractedText'],
          _titleController,
          _tagsController,
          _suggestedTags,
          (String? category) => setState(() => _selectedCategory = category),
          _showSuccessSnackBar,
          _showErrorSnackBar,
        );
        _showSuccessSnackBar(
          'File processed successfully! Content added to editor with formatting.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error processing file: ${e.toString()}');
    } finally {
      setState(() => _isProcessingFile = false);
    }
  }

  void _previewBlog() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title before previewing.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlogPreviewScreen(
              title: _titleController.text.trim(),
              controller: _controller,
              tags:
                  _tagsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
              category: _selectedCategory ?? AppConstants.defaultCategory,
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
        // _showErrorSnackBar,
        // _showSuccessSnackBar,
      );
      _clearForm();
    } catch (e) {
      _showErrorSnackBar('Error publishing blog: ${e.toString()}');
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

  void _showErrorSnackBar(String message) {
    UIUtils.showErrorSnackBar(context, message);
  }

  void _showSuccessSnackBar(String message) {
    UIUtils.showSuccessSnackBar(context, message);
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _previewBlog,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.preview,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // File Upload Section
            _buildSection(
              title: 'Document Upload',
              icon: Icons.upload_file,
              child: UIUtils.buildFileUploadSection(
                context,
                _uploadedFileName,
                _isProcessingFile,
                _uploadFile,
              ),
            ),

            const SizedBox(height: 24),

            // Blog Details Section
            _buildSection(
              title: 'Blog Details',
              icon: Icons.article,
              child: Column(
                children: [
                  UIUtils.buildTitleInput(context, _titleController),
                  const SizedBox(height: 20),
                  UIUtils.buildCategorySelector(
                    context,
                    _selectedCategory,
                    (String? value) =>
                        setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: 20),
                  UIUtils.buildTagsInput(
                    context,
                    _tagsController,
                    _suggestedTags,
                    _isGeneratingTags,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content Editor Section
            _buildSection(
              title: 'Content Editor',
              icon: Icons.edit,
              child: UIUtils.buildQuillEditor(context, _controller),
            ),

            const SizedBox(height: 32),

            // Action Buttons
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.clear, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
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
            ),

            const SizedBox(height: 24),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
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
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}
