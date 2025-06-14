import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/models/course.dart';
import 'package:test_project/services/database_service.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/widgets/custom_bottom_navbar.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _userName;
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.fetchUserData();
    if (userData != null) {
      setState(() {
        _userName = userData.displayName;
        _photoUrl = userData.photoURL;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddPlanDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedImage;
    List<String> selectedCategories = [];
    bool isSaving = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                'Create New Fitness Plan',
                style: TextStyle(color: theme.primaryColor),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: theme.primaryColor),
                      decoration: InputDecoration(
                        labelText: 'Plan Title',
                        hintText: 'Enter plan title',
                        hintStyle: TextStyle(color: theme.primaryColor),
                        labelStyle: TextStyle(color: theme.primaryColor),
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(color: theme.primaryColor),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter plan description',
                        hintStyle: TextStyle(color: theme.primaryColor),
                        labelStyle: TextStyle(color: theme.primaryColor),
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Plan Cover Image',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                    const SizedBox(height: 8),
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.primaryColor),
                        ),
                        child:
                            selectedImage != null
                                ? Image.file(selectedImage!, fit: BoxFit.cover)
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: theme.primaryColor,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Cover Image',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Plan Categories',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCategoryChip(
                          'Weight Loss',
                          selectedCategories,
                          setState,
                        ),
                        _buildCategoryChip(
                          'Muscle Gain',
                          selectedCategories,
                          setState,
                        ),
                        _buildCategoryChip(
                          'Cardio',
                          selectedCategories,
                          setState,
                        ),
                        _buildCategoryChip(
                          'Nutrition',
                          selectedCategories,
                          setState,
                        ),
                        _buildCategoryChip(
                          'Yoga',
                          selectedCategories,
                          setState,
                        ),
                      ],
                    ),
                    if (isSaving)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
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
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                            if (titleController.text.isEmpty ||
                                descriptionController.text.isEmpty) {
                              AppNotifier.show(
                                context,
                                'Please fill all required fields',
                                type: MessageType.warning,
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
                              subjects: selectedCategories,
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
                  child: Text(
                    'Save',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    List<String> selectedCategories,
    Function setState,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedCategories.contains(label);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.primaryColor,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.primaryColor,
      ),
      side: const BorderSide(
        color: Color.fromRGBO(10, 45, 123, 1.0),
        width: 1.0,
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            selectedCategories.add(label);
          } else {
            selectedCategories.remove(label);
          }
        });
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Fitness Plans Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first fitness plan',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPlanDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Plan',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(List<Course> courses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildPlanCard(course);
      },
    );
  }

  Widget _buildPlanCard(Course course) {
    final theme = Theme.of(context);
    // Format DateTime
    String formattedDate = 'Date not available';
    if (course.createdAt != null) {
      formattedDate = DateFormat('MMM d, yyyy').format(course.createdAt!);
    }

    final enrolledPatients = course.enrolledStudents;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/planDetails', arguments: course.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan image
            SizedBox(
              height: 160,
              width: double.infinity,
              child:
                  course.coverImageUrl != null &&
                          course.coverImageUrl!.isNotEmpty
                      ? Image.network(
                        course.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: Colors.grey[100],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: theme.primaryColor,
                              ),
                            ),
                      )
                      : Container(
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.fitness_center,
                          size: 50,
                          color: theme.primaryColor,
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title.isNotEmpty ? course.title : 'Untitled Plan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description.isNotEmpty
                        ? course.description
                        : 'No description',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: theme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '${enrolledPatients.length} Patients',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/planDetails',
                            arguments: course.id,
                          );
                        },
                        icon: Icon(Icons.edit, color: theme.primaryColor),
                        label: Text(
                          'Manage',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(course.id),
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

  void _showDeleteConfirmation(String planId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Delete Fitness Plan',
            style: TextStyle(color: theme.primaryColor),
          ),
          content: Text(
            'Are you sure you want to delete this fitness plan? This action cannot be undone.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.deleteCourse(planId, context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _authService.signOut(context),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: SpinKitDoubleBounce(
                  color: Color(0xFF0A2D7B),
                  size: 40.0,
                ),
              )
              : StreamBuilder<List<Course>>(
                stream: _databaseService.fetchTutorCoursesRealTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SpinKitDoubleBounce(
                        color: Color(0xFF0A2D7B),
                        size: 40.0,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    AppNotifier.show(
                      context,
                      'Error loading courses: ${snapshot.error}',
                      type: MessageType.error,
                    );
                    return const Center(child: Text('Error loading courses'));
                  }

                  final courses = snapshot.data ?? [];
                  return courses.isEmpty
                      ? _buildEmptyState()
                      : _buildPlansList(courses);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlanDialog,
        backgroundColor: theme.primaryColor,
        tooltip: 'Add New Fitness Plan',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentRoute: '/doctorDashboard'),
    );
  }
}
