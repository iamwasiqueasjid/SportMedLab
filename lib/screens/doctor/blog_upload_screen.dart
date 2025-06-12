import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';

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
  List<String> _categories = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Pediatrics',
    'Surgery',
    'Mental Health',
    'Nutrition',
    'Preventive Care',
    'Emergency Medicine'
  ];

  List<String> _suggestedTags = [];
  bool _isProcessingFile = false;
  bool _isGeneratingTags = false;
  bool _isPublishing = false;
  String? _extractedText;
  String? _uploadedFileName;

  final String currentDoctorId = 'doctor123'; // Replace with actual user ID

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

  // File upload and processing
  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isProcessingFile = true;
        _uploadedFileName = result.files.single.name;
      });

      try {
        File file = File(result.files.single.path!);
        String extractedText = '';

        if (result.files.single.extension?.toLowerCase() == 'pdf') {
          extractedText = await _extractTextFromPDF(file);
        } else if (result.files.single.extension?.toLowerCase() == 'docx' ||
            result.files.single.extension?.toLowerCase() == 'doc') {
          extractedText = await _extractTextFromWord(file);
        }

        if (extractedText.isNotEmpty) {
          _extractedText = extractedText;
          await _processExtractedText(extractedText);
          _showSuccessSnackBar('File processed successfully! Content added to editor.');
        } else {
          _showErrorSnackBar('No text could be extracted from the file.');
        }
      } catch (e) {
        _showErrorSnackBar('Error processing file: ${e.toString()}');
      } finally {
        setState(() {
          _isProcessingFile = false;
        });
      }
    }
  }

  // Extract text from PDF
  Future<String> _extractTextFromPDF(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = '';

      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        text += PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        text += '\n\n';
      }

      document.dispose();
      return text.trim();
    } catch (e) {
      throw Exception('Failed to extract text from PDF: ${e.toString()}');
    }
  }

  // Extract text from Word document
  Future<String> _extractTextFromWord(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final text = docxToText(bytes);
      return text ?? '';
    } catch (e) {
      throw Exception('Failed to extract text from Word document: ${e.toString()}');
    }
  }

  // Process extracted text with AI
  Future<void> _processExtractedText(String text) async {
    setState(() {
      _isGeneratingTags = true;
    });

    try {
      // Auto-fill content in Quill editor
      await _populateQuillEditor(text);

      // Generate title, tags, and category using Gemini AI
      await _generateMetadataWithAI(text);

    } catch (e) {
      _showErrorSnackBar('Error processing text with AI: ${e.toString()}');
    } finally {
      setState(() {
        _isGeneratingTags = false;
      });
    }
  }

  // FIXED: Populate Quill editor with formatted text
  Future<void> _populateQuillEditor(String text) async {
    try {
      // Clear existing content safely
      _controller.clear();

      // Wait a frame to ensure the clear operation is complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Split text into paragraphs
      List<String> paragraphs = text.split('\n').where((p) => p.trim().isNotEmpty).toList();

      // Build the document content as a single operation
      String fullContent = '';
      List<Map<String, dynamic>> formatOperations = [];

      int currentPosition = 0;

      for (int i = 0; i < paragraphs.length; i++) {
        String paragraph = paragraphs[i].trim();
        if (paragraph.isNotEmpty) {
          // Check if it looks like a heading before adding to content
          bool isHeading = _isLikelyHeading(paragraph);

          // Add the paragraph text
          fullContent += paragraph;

          // Store formatting operation for later
          if (isHeading) {
            formatOperations.add({
              'start': currentPosition,
              'length': paragraph.length,
              'attribute': Attribute.h2,
            });
          }

          currentPosition += paragraph.length;

          // Add line breaks except for the last paragraph
          if (i < paragraphs.length - 1) {
            fullContent += '\n\n';
            currentPosition += 2;
          }
        }
      }

      // Insert all content at once if there's content to insert
      if (fullContent.isNotEmpty) {
        _controller.document.insert(0, fullContent);

        // Apply formatting operations
        for (var operation in formatOperations) {
          try {
            _controller.formatText(
              operation['start'],
              operation['length'],
              operation['attribute'],
            );
          } catch (e) {
            print('Error applying formatting: $e');
            // Continue with other formatting operations
          }
        }
      }
    } catch (e) {
      print('Error populating Quill editor: $e');
      _showErrorSnackBar('Error formatting document content');
    }
  }

  // Check if text looks like a heading
  bool _isLikelyHeading(String text) {
    // Heading characteristics: short, less than 100 chars, few sentences
    return text.length < 100 &&
        text.split('.').length <= 2 &&
        text.split(' ').length <= 10 &&
        !text.endsWith('.');
  }

  // Generate metadata using Gemini AI
  Future<void> _generateMetadataWithAI(String text) async {
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      _showErrorSnackBar('Gemini API key not found. Using fallback tag generation.');
      _generateBasicTags(text);
      return;
    }

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey');

    // Limit text to avoid API limits
    String analyzableText = text.length > 2000 ? text.substring(0, 2000) : text;

    final prompt = """
    Analyze the following medical/health blog content and provide metadata in JSON format only:

    {
      "title": "A suitable blog title (max 80 characters)",
      "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"],
      "category": "Most appropriate category from: ${_categories.join(', ')}"
    }

    Rules:
    - Title should be engaging and professional
    - Tags should be relevant medical/health terms
    - Category must be exactly one from the provided list
    - Response must be valid JSON only

    Content:
    $analyzableText
    """;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final generatedText = data['candidates'][0]['content']['parts'][0]['text'];

          // Try to extract JSON from the response
          try {
            // Find JSON in the response
            final jsonStart = generatedText.indexOf('{');
            final jsonEnd = generatedText.lastIndexOf('}') + 1;

            if (jsonStart != -1 && jsonEnd > jsonStart) {
              final jsonString = generatedText.substring(jsonStart, jsonEnd);
              final jsonData = json.decode(jsonString);

              setState(() {
                if (jsonData['title'] != null && jsonData['title'].toString().isNotEmpty) {
                  _titleController.text = jsonData['title'].toString();
                }

                if (jsonData['tags'] != null && jsonData['tags'] is List) {
                  _suggestedTags = List<String>.from(jsonData['tags']);
                  _tagsController.text = _suggestedTags.join(', ');
                }

                if (jsonData['category'] != null &&
                    _categories.contains(jsonData['category'].toString())) {
                  _selectedCategory = jsonData['category'].toString();
                }
              });

              _showSuccessSnackBar('AI analysis complete! Review the suggested metadata.');
              return;
            }
          } catch (e) {
            print('JSON parsing error: $e');
          }
        }
      }

      // If AI fails, use fallback
      _generateBasicTags(text);

    } catch (e) {
      print('Error calling Gemini API: $e');
      _generateBasicTags(text);
    }
  }

  // Fallback method to generate basic tags and title
  void _generateBasicTags(String text) {
    List<String> medicalTerms = [
      'treatment', 'diagnosis', 'symptoms', 'patient', 'health', 'medical',
      'therapy', 'disease', 'condition', 'medicine', 'care', 'clinical',
      'prevention', 'wellness', 'healthcare', 'recovery'
    ];

    List<String> foundTags = [];
    String lowerText = text.toLowerCase();

    for (String term in medicalTerms) {
      if (lowerText.contains(term) && !foundTags.contains(term)) {
        foundTags.add(term);
        if (foundTags.length >= 6) break;
      }
    }

    // Generate basic title if empty
    if (_titleController.text.isEmpty) {
      List<String> sentences = text.split('.').where((s) => s.trim().isNotEmpty).toList();
      if (sentences.isNotEmpty) {
        String firstSentence = sentences[0].trim();
        if (firstSentence.length > 80) {
          firstSentence = firstSentence.substring(0, 77) + '...';
        }
        _titleController.text = firstSentence;
      }
    }

    setState(() {
      _suggestedTags = foundTags;
      if (foundTags.isNotEmpty) {
        _tagsController.text = foundTags.join(', ');
      }
    });

    _showSuccessSnackBar('Basic metadata generated. AI analysis unavailable.');
  }

  // Preview blog
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
          category: _selectedCategory ?? 'General Medicine',
        ),
      ),
    );
  }

  // Submit blog
  Future<void> _publishBlog() async {
    final title = _titleController.text.trim();
    final delta = _controller.document.toDelta();
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Validation
    if (title.isEmpty) {
      _showErrorSnackBar('Please enter a blog title.');
      return;
    }

    if (_controller.document.isEmpty()) {
      _showErrorSnackBar('Please add some content to your blog.');
      return;
    }

    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category.');
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      // Create blog document
      final blogData = {
        'title': title,
        'content': delta.toJson(),
        'tags': tags,
        'category': _selectedCategory,
        'authorId': currentDoctorId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isPublished': true,
        'viewCount': 0,
        'likeCount': 0,
      };

      // Add extracted text if available (for search functionality)
      if (_extractedText != null) {
        blogData['extractedText'] = _extractedText;
        blogData['sourceFile'] = _uploadedFileName;
      }

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('blogs')
          .add(blogData);

      _showSuccessSnackBar('Blog published successfully!');

      // Clear form after successful publication
      _clearForm();

      // Optionally navigate back or to blog list
      // Navigator.pop(context);

    } catch (e) {
      _showErrorSnackBar('Error publishing blog: ${e.toString()}');
    } finally {
      setState(() {
        _isPublishing = false;
      });
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Blog Editor'),
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
            // File upload section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Document',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload PDF or Word document to auto-populate content and generate metadata',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_uploadedFileName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Uploaded: $_uploadedFileName',
                                style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessingFile ? null : _uploadFile,
                        icon: _isProcessingFile
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.upload_file),
                        label: Text(_isProcessingFile ? 'Processing...' : 'Upload PDF/Word File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Blog Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                helperText: 'Enter an engaging title for your blog',
              ),
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // FIXED: Category and Tags - Changed to Column layout for smaller screens
            LayoutBuilder(
              builder: (context, constraints) {
                // Use Row for wider screens, Column for narrow screens
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      // Category dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Tags field
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _tagsController,
                          decoration: InputDecoration(
                            labelText: 'Tags',
                            border: const OutlineInputBorder(),
                            prefixIcon: _isGeneratingTags
                                ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                                : const Icon(Icons.local_offer),
                            helperText: 'Comma separated tags',
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Column layout for smaller screens
                  return Column(
                    children: [
                      // Category dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // Tags field
                      TextField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: 'Tags',
                          border: const OutlineInputBorder(),
                          prefixIcon: _isGeneratingTags
                              ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                              : const Icon(Icons.local_offer),
                          helperText: 'Comma separated tags',
                        ),
                        maxLines: 1,
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // Quill toolbar
            QuillSimpleToolbar(
              controller: _controller,
              config: const QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showSubscript: false,
                showSuperscript: false,
                showSearchButton: false,
              ),
            ),

            const SizedBox(height: 8),

            // Quill editor - Fixed height for scrollable screen
            Container(
              height: 300, // Fixed height to ensure screen scrollability
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QuillEditor.basic(
                controller: _controller,
                config: QuillEditorConfig(
                  placeholder: 'Start writing your blog content here...\n\nTip: Upload a PDF or Word document to auto-populate content!',
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previewBlog,
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isPublishing ? null : _publishBlog,
                    icon: _isPublishing
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.publish),
                    label: Text(_isPublishing ? 'Publishing...' : 'Publish Blog'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Blog Preview Screen
class BlogPreviewScreen extends StatelessWidget {
  final String title;
  final QuillController controller;
  final List<String> tags;
  final String category;

  const BlogPreviewScreen({
    Key? key,
    required this.title,
    required this.controller,
    required this.tags,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 12),

            // Metadata row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Published: ${DateTime.now().toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tags
            if (tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Divider
            Divider(color: Colors.grey.shade300, thickness: 1),

            const SizedBox(height: 16),

            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: QuillEditor.basic(
                controller: controller,
                config: const QuillEditorConfig(
                  enableInteractiveSelection: false,
                  showCursor: false,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Back to edit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.edit),
                label: const Text('Back to Edit'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}