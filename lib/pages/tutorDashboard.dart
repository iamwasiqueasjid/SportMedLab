// lib/screens/tutor_dashboard.dart
import 'package:test_project/services/databaseHandler.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TutorDashboard extends StatefulWidget {
  const TutorDashboard({Key? key}) : super(key: key);

  @override
  State<TutorDashboard> createState() => _TutorDashboardState();
}

class _TutorDashboardState extends State<TutorDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _userName;
  String? _photoUrl;
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _databaseService.fetchUserData();
    if (userData != null) {
      setState(() {
        _userName = userData['displayName'];
        _photoUrl = userData['photoURL'];
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddCourseDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedImage;
    List<String> selectedSubjects = [];
    bool isSaving = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create New Course'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Course Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    Text('Course Cover Image'),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          setState(() {
                            selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child:
                            selectedImage != null
                                ? Image.file(selectedImage!, fit: BoxFit.cover)
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 50),
                                      SizedBox(height: 8),
                                      Text('Add Cover Image'),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Course Subjects'),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildSubjectChip('Math', selectedSubjects, setState),
                        _buildSubjectChip(
                          'Science',
                          selectedSubjects,
                          setState,
                        ),
                        _buildSubjectChip(
                          'History',
                          selectedSubjects,
                          setState,
                        ),
                        _buildSubjectChip(
                          'Languages',
                          selectedSubjects,
                          setState,
                        ),
                        _buildSubjectChip(
                          'Programming',
                          selectedSubjects,
                          setState,
                        ),
                      ],
                    ),
                    if (isSaving)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(child: CircularProgressIndicator()),
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
                  child: Text('Save'),
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                            if (titleController.text.isEmpty ||
                                descriptionController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please fill all required fields',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              isSaving = true;
                            });

                            final success = await _databaseService.createCourse(
                              title: titleController.text,
                              description: descriptionController.text,
                              imageFile: selectedImage,
                              subjects: selectedSubjects,
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
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectChip(
    String label,
    List<String> selectedSubjects,
    Function setState,
  ) {
    final isSelected = selectedSubjects.contains(label);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            selectedSubjects.add(label);
          } else {
            selectedSubjects.remove(label);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tutor Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _databaseService.signOut(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage:
                        _photoUrl != null
                            ? NetworkImage(_photoUrl!)
                            : AssetImage('assets/images/avatar.png')
                                as ImageProvider,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _userName ?? 'Tutor',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Tutor',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                _databaseService.signOut(context);
              },
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _databaseService.fetchTutorCoursesRealTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final courses = snapshot.data ?? [];

                  return courses.isEmpty
                      ? _buildEmptyState()
                      : _buildCoursesList(courses);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        child: Icon(Icons.add),
        tooltip: 'Add New Course',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Courses Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first micro-course',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCourseDialog,
            icon: Icon(Icons.add),
            label: Text('Create Course'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(List<Map<String, dynamic>> courses) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    // Format timestamp
    String formattedDate = 'Date not available';
    if (course['createdAt'] != null) {
      final timestamp = course['createdAt'] as Timestamp;
      formattedDate = DateFormat('MMM d, yyyy').format(timestamp.toDate());
    }

    final enrolledStudents = course['enrolledStudents'] as List? ?? [];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/courseDetails',
            arguments: course['id'],
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            Container(
              height: 160,
              width: double.infinity,
              child:
                  course['coverImageUrl'] != null &&
                          course['coverImageUrl'].isNotEmpty
                      ? Image.network(
                        course['coverImageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                      )
                      : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.school, size: 50),
                      ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'] ?? 'Untitled Course',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    course['description'] ?? 'No description',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text('${enrolledStudents.length} Students'),
                      SizedBox(width: 16),
                      Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(formattedDate),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/courseDetails',
                            arguments: course['id'],
                          );
                        },
                        icon: Icon(Icons.edit),
                        label: Text('Manage'),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(course['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String courseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Course'),
          content: Text(
            'Are you sure you want to delete this course? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.deleteCourse(courseId, context);
              },
            ),
          ],
        );
      },
    );
  }
}
