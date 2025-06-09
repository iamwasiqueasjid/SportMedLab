import 'package:test_project/services/database_service.dart';
import 'package:test_project/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:test_project/utils/custom_drawer.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

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
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.fetchUserData();
    if (userData != null) {
      setState(() {
        _userName = userData['displayName'];
        _photoUrl = userData['photoURL'];
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
              backgroundColor: Colors.white, // Match LoginScreen
              title: Text(
                'Create New Fitness Plan',
                style: TextStyle(
                  color: theme.primaryColor,
                ), // Match LoginScreen
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: theme.primaryColor,
                      ), // Match LoginScreen
                      decoration: InputDecoration(
                        labelText: 'Plan Title',
                        hintText: 'Enter plan title',
                        hintStyle: TextStyle(color: theme.primaryColor),
                        labelStyle: TextStyle(color: theme.primaryColor),
                        filled: true,
                        fillColor: Colors.grey[100], // Match LoginScreen
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
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(
                        color: theme.primaryColor,
                      ), // Match LoginScreen
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter plan description',
                        hintStyle: TextStyle(color: theme.primaryColor),
                        labelStyle: TextStyle(color: theme.primaryColor),
                        filled: true,
                        fillColor: Colors.grey[100], // Match LoginScreen
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
                    SizedBox(height: 16),
                    Text(
                      'Plan Cover Image',
                      style: TextStyle(
                        color: theme.primaryColor,
                      ), // Match LoginScreen
                    ),
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
                          color: Colors.grey[100], // Match LoginScreen
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
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
                                        color:
                                            theme
                                                .primaryColor, // Match LoginScreen
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Add Cover Image',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                        ), // Match LoginScreen
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Plan Categories',
                      style: TextStyle(
                        color: theme.primaryColor,
                      ), // Match LoginScreen
                    ),
                    SizedBox(height: 8),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor, // Match LoginScreen
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
                    style: TextStyle(
                      color: theme.primaryColor,
                    ), // Match LoginScreen
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: theme.primaryColor,
                    ), // Match LoginScreen
                  ),
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
      selectedColor:
          theme.primaryColor, // Solid primary color for selected state
      checkmarkColor:
          Colors.white, // White checkmark to contrast with primary color
      backgroundColor: Colors.grey[200], // Grey background for unselected state
      labelStyle: TextStyle(
        color:
            isSelected
                ? Colors.white
                : theme
                    .primaryColor, // White when selected, primary color when unselected
      ),
      side: BorderSide(
        color: Color.fromRGBO(
          10,
          45,
          123,
          1.0,
        ), // Primary color border with full opacity
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white, // Match LoginScreen
      appBar: AppBar(
        backgroundColor: theme.primaryColor, // Match LoginScreen
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Doctor Dashboard',
          style: TextStyle(color: Colors.white), // Match LoginScreen
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white), // Match LoginScreen
            onPressed: () => _authService.signOut(context),
          ),
        ],
      ),
      drawer: CustomDrawer(
        userName: _userName,
        photoUrl: _photoUrl,
        role: 'Doctor',
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.primaryColor, // Match LoginScreen
                ),
              )
              : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _databaseService.fetchTutorCoursesRealTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor, // Match LoginScreen
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final plans = snapshot.data ?? [];

                  return plans.isEmpty
                      ? _buildEmptyState()
                      : _buildPlansList(plans);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlanDialog,
        backgroundColor: theme.primaryColor, // Match LoginScreen
        child: Icon(Icons.add, color: Colors.white), // Match LoginScreen
        tooltip: 'Add New Fitness Plan',
      ),
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
            color: Colors.grey[600], // Match LoginScreen
          ),
          SizedBox(height: 16),
          Text(
            'No Fitness Plans Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Match LoginScreen
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first fitness plan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600], // Match LoginScreen
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPlanDialog,
            icon: Icon(Icons.add, color: Colors.white), // Match LoginScreen
            label: Text(
              'Create Plan',
              style: TextStyle(color: Colors.white), // Match LoginScreen
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor, // Match LoginScreen
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Match LoginScreen
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(List<Map<String, dynamic>> plans) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    // Format timestamp
    String formattedDate = 'Date not available';
    if (plan['createdAt'] != null) {
      final timestamp = plan['createdAt'] as Timestamp;
      formattedDate = DateFormat('MMM d, yyyy').format(timestamp.toDate());
    }

    final enrolledPatients = plan['enrolledStudents'] as List? ?? [];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match LoginScreen
      ),
      elevation: 4,
      color: Colors.white, // Match LoginScreen
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/planDetails', // Updated to reflect fitness plans
            arguments: plan['id'],
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan image
            Container(
              height: 160,
              width: double.infinity,
              child:
                  plan['coverImageUrl'] != null &&
                          plan['coverImageUrl'].isNotEmpty
                      ? Image.network(
                        plan['coverImageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: Colors.grey[100], // Match LoginScreen
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: theme.primaryColor, // Match LoginScreen
                              ),
                            ),
                      )
                      : Container(
                        color: Colors.grey[100], // Match LoginScreen
                        child: Icon(
                          Icons.fitness_center,
                          size: 50,
                          color: theme.primaryColor, // Match LoginScreen
                        ),
                      ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['title'] ?? 'Untitled Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Match LoginScreen
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    plan['description'] ?? 'No description',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600], // Match LoginScreen
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: theme.primaryColor, // Match LoginScreen
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${enrolledPatients.length} Patients',
                        style: TextStyle(
                          color: theme.primaryColor,
                        ), // Match LoginScreen
                      ),
                      SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.primaryColor, // Match LoginScreen
                      ),
                      SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: theme.primaryColor,
                        ), // Match LoginScreen
                      ),
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
                            '/planDetails', // Updated to reflect fitness plans
                            arguments: plan['id'],
                          );
                        },
                        icon: Icon(
                          Icons.edit,
                          color: theme.primaryColor, // Match LoginScreen
                        ),
                        label: Text(
                          'Manage',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Match LoginScreen
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red, // Keep red for delete
                        ),
                        onPressed: () => _showDeleteConfirmation(plan['id']),
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
          backgroundColor: Colors.white, // Match LoginScreen
          title: Text(
            'Delete Fitness Plan',
            style: TextStyle(color: theme.primaryColor), // Match LoginScreen
          ),
          content: Text(
            'Are you sure you want to delete this fitness plan? This action cannot be undone.',
            style: TextStyle(color: Colors.grey[700]), // Match LoginScreen
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.primaryColor,
                ), // Match LoginScreen
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red), // Keep red for delete
              ),
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
}
