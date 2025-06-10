import 'package:test_project/models/course.dart';
import 'package:test_project/models/lesson.dart';
import 'package:test_project/services/database_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  Course? _courseData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      final data = await _databaseService.getCourseById(widget.courseId);
      setState(() {
        _courseData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppNotifier.show(
        context,
        'Error loading course: $e',
        type: MessageType.error,
      );
    }
  }

  Future<void> _showAddLessonDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String contentType = 'text'; // Default content type
    File? selectedFile;
    bool isSaving = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Lesson'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Lesson Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: contentType,
                      decoration: InputDecoration(
                        labelText: 'Content Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'text', child: Text('Text')),
                        DropdownMenuItem(value: 'image', child: Text('Image')),
                        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          contentType = value!;
                          // Clear file if switching to text
                          if (contentType == 'text') {
                            selectedFile = null;
                          }
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    if (contentType == 'text') ...[
                      TextField(
                        controller: contentController,
                        decoration: InputDecoration(
                          labelText: 'Lesson Content',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                    ] else ...[
                      Text('Upload ${contentType.toUpperCase()} File'),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          if (contentType == 'image') {
                            final pickedFile = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                selectedFile = File(pickedFile.path);
                              });
                            }
                          } else if (contentType == 'pdf') {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf'],
                                );

                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() {
                                selectedFile = File(result.files.single.path!);
                              });
                            }
                          }
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child:
                              selectedFile != null
                                  ? contentType == 'image'
                                      ? Image.file(
                                        selectedFile!,
                                        fit: BoxFit.contain,
                                      )
                                      : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.description, size: 40),
                                            SizedBox(height: 8),
                                            Text(
                                              selectedFile!.path
                                                  .split('/')
                                                  .last,
                                            ),
                                          ],
                                        ),
                                      )
                                  : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          contentType == 'image'
                                              ? Icons.add_photo_alternate
                                              : Icons.upload_file,
                                          size: 40,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Upload ${contentType.toUpperCase()}',
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: 16),
                      if (contentType != 'text') ...[
                        TextField(
                          controller: contentController,
                          decoration: InputDecoration(
                            labelText: 'Text Description (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ],
                    if (isSaving)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: SpinKitDoubleBounce(
                            color: Color(0xFF0A2D7B),
                            size: 40.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                            if (titleController.text.isEmpty) {
                              AppNotifier.show(
                                context,
                                'Lesson title is required',
                                type: MessageType.warning,
                              );
                              return;
                            }

                            if (contentType == 'text' &&
                                contentController.text.isEmpty) {
                              AppNotifier.show(
                                context,
                                'Lesson content is required',
                                type: MessageType.warning,
                              );
                              return;
                            }

                            if (contentType != 'text' && selectedFile == null) {
                              AppNotifier.show(
                                context,
                                'Please upload a $contentType file',
                                type: MessageType.warning,
                              );
                              return;
                            }

                            setState(() {
                              isSaving = true;
                            });

                            final success = await _databaseService.createLesson(
                              courseId: widget.courseId,
                              title: titleController.text,
                              contentType: contentType,
                              content: contentController.text,
                              file: selectedFile,
                              context: context,
                            );

                            if (success) {
                              Navigator.of(context).pop();
                            } else {
                              setState(() {
                                isSaving = false;
                              });
                            }
                          },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Course Details' : 'Course: ${_courseData?.title ?? ''}',
        ),
        backgroundColor: Colors.indigo,
      ),
      body:
          _isLoading
              ? Center(
                child: SpinKitDoubleBounce(
                  color: Color(0xFF0A2D7B),
                  size: 40.0,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course header
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child:
                        _courseData != null &&
                                _courseData!.coverImageUrl != null &&
                                _courseData!.coverImageUrl!.isNotEmpty
                            ? Image.network(
                              _courseData!.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                            )
                            : Container(
                              color: Colors.indigo,
                              child: Center(
                                child: Icon(
                                  Icons.school,
                                  size: 70,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _courseData != null
                              ? (_courseData!.title ?? 'Untitled Course')
                              : 'Untitled Course',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _courseData != null
                              ? (_courseData!.description ?? 'No description')
                              : 'No description',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lessons',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAddLessonDialog,
                              icon: Icon(Icons.add),
                              label: Text('Add Lesson'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Lessons list
                  Expanded(
                    child: StreamBuilder<List<Lesson>>(
                      stream: _databaseService.fetchLessonsForCourse(
                        widget.courseId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: SpinKitDoubleBounce(
                              color: Color(0xFF0A2D7B),
                              size: 40.0,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final lessons = snapshot.data ?? [];

                        if (lessons.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No lessons yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add your first lesson to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = lessons[index];
                            return _buildLessonCard(lesson.toMap());
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLessonDialog,
        backgroundColor: Colors.indigo,
        tooltip: 'Add New Lesson',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    final IconData contentIcon;
    final String contentTypeText;

    switch (lesson['contentType']) {
      case 'image':
        contentIcon = Icons.image;
        contentTypeText = 'Image';
        break;
      case 'pdf':
        contentIcon = Icons.picture_as_pdf;
        contentTypeText = 'PDF';
        break;
      case 'text':
      default:
        contentIcon = Icons.text_snippet;
        contentTypeText = 'Text';
        break;
    }

    // Check if this is a text lesson without an AI summary
    bool needsAIContent =
        lesson['contentType'] == 'text' &&
        (lesson['summary'] == null || lesson['summary'].isEmpty);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(contentIcon, color: Colors.indigo),
            ),
            title: Text(
              lesson['title'] ?? 'Untitled Lesson',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(contentTypeText),
                SizedBox(height: 4),
                if (lesson['createdAt'] != null)
                  Text(
                    'Added: ${DateFormat('MMM d, yyyy').format((lesson['createdAt'] as Timestamp).toDate())}',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // Edit lesson functionality could be added later
                    AppNotifier.show(
                      context,
                      'Edit lesson feature coming soon',
                      type: MessageType.info,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteLessonConfirmation(lesson['id']),
                ),
              ],
            ),
            onTap: () {
              // View lesson details
              _showLessonDetails(lesson);
            },
          ),

          // Add the Generate AI Content button here if needed
          if (needsAIContent)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: Icon(Icons.auto_awesome, color: Colors.indigo),
                      label: Text('Generate AI Content'),
                      onPressed: () async {
                        // Show loading indicator
                        AppNotifier.show(
                          context,
                          'Generating AI content...',
                          type: MessageType.info,
                        );

                        // Call the method to generate and update AI content
                        final success = await _databaseService
                            .updateLessonWithAIContent(
                              lessonId: lesson['id'],
                              content: lesson['content'],
                            );

                        if (success) {
                          AppNotifier.show(
                            context,
                            'AI content generated successfully',
                            type: MessageType.success,
                          );
                        } else {
                          AppNotifier.show(
                            context,
                            'Failed to generate AI summary or flashcards',
                            type: MessageType.error,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteLessonConfirmation(String lessonId) {
    // Your existing delete lesson confirmation dialog
  }
  void _showLessonDetails(Map<String, dynamic> lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  // Other lesson content display...

                  // AI Summary Section
                  SizedBox(height: 32),
                  Text(
                    'AI-Generated Summary:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lesson['summary'] != null && lesson['summary'].isNotEmpty
                          ? lesson['summary']
                          : 'AI summary not available yet.',
                      style: TextStyle(
                        fontStyle:
                            lesson['summary'] == null ||
                                    lesson['summary'].isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                      ),
                    ),
                  ),

                  // Flashcards Section
                  SizedBox(height: 24),
                  Text(
                    'AI-Generated Flashcards:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  // If there are flashcards, display them
                  if (lesson['flashcards'] != null &&
                      lesson['flashcards'] is List &&
                      (lesson['flashcards'] as List).isNotEmpty)
                    ...buildFlashcards(lesson['flashcards']),

                  // If no flashcards are available
                  if (lesson['flashcards'] == null ||
                      lesson['flashcards'] is! List ||
                      (lesson['flashcards'] as List).isEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Flashcards not available yet.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> buildFlashcards(List flashcards) {
    return flashcards.map<Widget>((card) {
      return Card(
        margin: EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          title: Text(
            card['question'] ?? 'Question',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(card['answer'] ?? 'Answer'),
            ),
          ],
        ),
      );
    }).toList();
  }
}
