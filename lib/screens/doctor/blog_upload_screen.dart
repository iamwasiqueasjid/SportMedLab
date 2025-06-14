import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../Services/file_processor.dart';
import '../../utils/content_formatter.dart';
import '../../utils/content_formatter.dart';
import '../../services/metadata_service.dart';
import '../../Services/blog_service.dart';
import '../../widgets/ui_utils.dart' ; // Use alias to avoid conflicts
import 'blog_preview_screen.dart';
import '../../constants/constants.dart';



class AdvancedBlogEditorScreen extends StatefulWidget {
  const AdvancedBlogEditorScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedBlogEditorScreen> createState() => _AdvancedBlogEditorScreenState();
}

class _AdvancedBlogEditorScreenState extends State<AdvancedBlogEditorScreen> {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String? _selectedCategory;
  List<String> _suggestedTags = [];
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
              (bool isGenerating) => setState(() => _isGeneratingTags = isGenerating),
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
        _showSuccessSnackBar('File processed successfully! Content added to editor with formatting.');
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
        builder: (context) => BlogPreviewScreen(
          title: _titleController.text.trim(),
          controller: _controller,
          tags: _tagsController.text
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
        _titleController,
        _controller,
        _tagsController,
        _selectedCategory,
        _extractedText,
        _uploadedFileName,
        _showErrorSnackBar,
        _showSuccessSnackBar,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Blog Editor'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _previewBlog,
            tooltip: 'Preview Blog',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            UIUtils.buildFileUploadSection(
              context,
              _uploadedFileName,
              _isProcessingFile,
              _uploadFile,
            ),
            const SizedBox(height: 16),
            UIUtils.buildTitleInput(context, _titleController),
            const SizedBox(height: 16),
            UIUtils.buildCategorySelector(
              context,
              _selectedCategory,
                  (String? value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
            UIUtils.buildTagsInput(
              context,
              _tagsController,
              _suggestedTags,
              _isGeneratingTags,
            ),
            const SizedBox(height: 16),
            UIUtils.buildQuillEditor(context, _controller),
            const SizedBox(height: 24),
            UIUtils.buildActionButtons(
              context,
              _isPublishing,
              _clearForm,
              _publishBlog,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}