import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/models/course.dart';
import 'package:test_project/screens/blogs/blog_list.dart';
import 'package:test_project/screens/chat/chat_list_screen.dart';
import 'package:test_project/screens/blogs/doctor_side/blog_upload.dart';
import 'package:test_project/screens/courses/course_lesson_screen.dart';
import 'package:test_project/screens/profile/edit_profile.dart';
import 'package:test_project/services/database_service.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';
import 'package:test_project/utils/responsive_widget.dart';
import 'package:test_project/widgets/app_message_notifier.dart'; // Added import for CourseLessonsScreen

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove the back button
        title: Text(
          'Doctor Dashboard',
          style: context.responsiveTitleLarge.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.white,
              size: ResponsiveHelper.getValue(
                context,
                mobile: 24.0,
                tablet: 26.0,
                desktop: 28.0,
              ),
            ),
            onPressed: () => _authService.signOut(context),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: SpinKitDoubleBounce(
                  color: const Color(0xFF0A2D7B),
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 40.0,
                    tablet: 50.0,
                    desktop: 60.0,
                  ),
                ),
              )
              : ResponsiveBuilder(
                builder: (context, constraints, deviceType) {
                  return _buildResponsiveLayout(context, theme, deviceType);
                },
              ),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    ThemeData theme,
    DeviceType deviceType,
  ) {
    switch (deviceType) {
      case DeviceType.desktop:
        return _buildDesktopLayout(context, theme);
      case DeviceType.tablet:
        return _buildTabletLayout(context, theme);
      // case DeviceType.mobile:
      default:
        return _buildMobileLayout(context, theme);
    }
  }

  Widget _buildBlogsTabs() {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: theme.primaryColor, // Match LoginScreen
            unselectedLabelColor: Colors.grey[600], // Match LoginScreen
            indicatorColor: theme.primaryColor, // Match LoginScreen
            tabs: [Tab(text: 'Published Blogs'), Tab(text: 'Add New Blog')],
          ),
          Expanded(
            child: TabBarView(
              children: [BlogList(), AdvancedBlogEditorWidget()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    final child = Padding(padding: EdgeInsets.all(0));
    return _buildTabBar(context, theme, child);
  }

  Widget _buildTabletLayout(BuildContext context, ThemeData theme) {
    final child = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getValue(
          context,
          mobile: 8.0,
          tablet: 16.0,
          desktop: 24.0,
        ),
      ),
    );
    return _buildTabBar(context, theme, child);
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    final child = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: EdgeInsets.all(
          ResponsiveHelper.getValue(
            context,
            mobile: 8.0,
            tablet: 12.0,
            desktop: 16.0,
          ),
        ),
      ),
    );
    return _buildTabBar(context, theme, child);
  }

  Widget _buildTabBar(BuildContext context, ThemeData theme, Widget child) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Expanded(
            child: TabBarView(
              children: [
                _buildCoursesTab(context, theme),
                _buildBlogsTabs(),
                ChatListWidget(),
                ProfileWidget(),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              margin: EdgeInsets.all(
                ResponsiveHelper.getValue(
                  context,
                  mobile: 8.0,
                  tablet: 12.0,
                  desktop: 16.0,
                ),
              ),
              decoration: BoxDecoration(
                // backgroundBlendMode: BlendMode.srcOver,
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.mediumSpacing),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: ResponsiveHelper.getValue(
                      context,
                      mobile: 12.0,
                      tablet: 16.0,
                      desktop: 20.0,
                    ),
                  ),
                ],
              ),
              child: TabBar(
                labelColor: theme.primaryColor,
                unselectedLabelColor: theme.primaryColor.withOpacity(0.8),
                indicatorColor: theme.primaryColor,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: context.responsiveBodyLarge,
                unselectedLabelStyle: context.responsiveBodyMedium,
                indicator: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.mediumSpacing),
                  border: Border(
                    top: BorderSide(
                      color: theme.primaryColor,
                      width: ResponsiveHelper.getValue(
                        context,
                        mobile: 2.0,
                        tablet: 2.5,
                        desktop: 3.0,
                      ),
                    ),
                  ),
                ),
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.description_outlined,
                      size: ResponsiveHelper.getValue(
                        context,
                        mobile: 20.0,
                        tablet: 22.0,
                        desktop: 24.0,
                      ),
                    ),
                    text: 'Courses',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.article_outlined,
                      size: ResponsiveHelper.getValue(
                        context,
                        mobile: 20.0,
                        tablet: 22.0,
                        desktop: 24.0,
                      ),
                    ),
                    text: 'Blogs',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: ResponsiveHelper.getValue(
                        context,
                        mobile: 20.0,
                        tablet: 22.0,
                        desktop: 24.0,
                      ),
                    ),
                    text: 'Chat',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.person_outline,
                      size: ResponsiveHelper.getValue(
                        context,
                        mobile: 20.0,
                        tablet: 22.0,
                        desktop: 24.0,
                      ),
                    ),
                    text: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.mediumSpacing),
              ),
              title: Text(
                'Create New Fitness Plan',
                style: context.responsiveHeadlineMedium.copyWith(
                  color: theme.primaryColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: ResponsiveHelper.getValue(
                    context,
                    mobile: double.infinity,
                    tablet: 400.0,
                    desktop: 600.0,
                  ),
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getValue(
                      context,
                      mobile: 8.0,
                      tablet: 12.0,
                      desktop: 16.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        style: context.responsiveBodyLarge.copyWith(
                          color: theme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Plan Title',
                          hintText: 'Enter plan title',
                          hintStyle: context.responsiveBodyMedium.copyWith(
                            color: theme.primaryColor,
                          ),
                          labelStyle: context.responsiveBodyMedium.copyWith(
                            color: theme.primaryColor,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.mediumSpacing),
                      TextField(
                        controller: descriptionController,
                        style: context.responsiveBodyLarge.copyWith(
                          color: theme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter plan description',
                          hintStyle: context.responsiveBodyMedium.copyWith(
                            color: theme.primaryColor,
                          ),
                          labelStyle: context.responsiveBodyMedium.copyWith(
                            color: theme.primaryColor,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: context.mediumSpacing),
                      Text(
                        'Plan Cover Image',
                        style: context.responsiveBodyLarge.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: context.smallSpacing),
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
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 150.0,
                            tablet: 200.0,
                            desktop: 250.0,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                            border: Border.all(color: theme.primaryColor),
                          ),
                          child:
                              selectedImage != null
                                  ? Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                  : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: ResponsiveHelper.getValue(
                                            context,
                                            mobile: 50.0,
                                            tablet: 60.0,
                                            desktop: 70.0,
                                          ),
                                          color: theme.primaryColor,
                                        ),
                                        SizedBox(height: context.smallSpacing),
                                        Text(
                                          'Add Cover Image',
                                          style: context.responsiveBodyMedium
                                              .copyWith(
                                                color: theme.primaryColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: context.mediumSpacing),
                      Text(
                        'Plan Categories',
                        style: context.responsiveBodyLarge.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: context.smallSpacing),
                      Wrap(
                        spacing: context.smallSpacing,
                        runSpacing: context.smallSpacing,
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
                          padding: EdgeInsets.only(top: context.mediumSpacing),
                          child: SpinKitDoubleBounce(
                            color: const Color(0xFF0A2D7B),
                            size: ResponsiveHelper.getValue(
                              context,
                              mobile: 40.0,
                              tablet: 50.0,
                              desktop: 60.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: context.responsiveBodyLarge.copyWith(
                      color: theme.primaryColor,
                    ),
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
                    style: context.responsiveBodyLarge.copyWith(
                      color: theme.primaryColor,
                    ),
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
      label: Text(
        label,
        style: context.responsiveBodyMedium.copyWith(
          color: isSelected ? Colors.white : theme.primaryColor,
        ),
      ),
      selected: isSelected,
      selectedColor: theme.primaryColor,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[200],
      labelStyle: context.responsiveBodyMedium.copyWith(
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

  Widget _buildCoursesTab(BuildContext context, ThemeData theme) {
    return StreamBuilder<List<Course>>(
      stream: _databaseService.fetchTutorCoursesRealTime(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitDoubleBounce(
              color: const Color(0xFF0A2D7B),
              size: ResponsiveHelper.getValue(
                context,
                mobile: 40.0,
                tablet: 50.0,
                desktop: 60.0,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          AppNotifier.show(
            context,
            'Error loading courses: ${snapshot.error}',
            type: MessageType.error,
          );
          return Center(
            child: Text(
              'Error loading courses',
              style: context.responsiveBodyLarge,
            ),
          );
        }

        final courses = snapshot.data ?? [];

        return courses.isEmpty
            ? _buildEmptyState(context, theme)
            : _buildPlansList(context, theme, courses);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: ResponsiveHelper.getValue(
              context,
              mobile: 80.0,
              tablet: 100.0,
              desktop: 120.0,
            ),
            color: Colors.grey[600],
          ),
          SizedBox(height: context.mediumSpacing),
          Text('No Fitness Plans Yet', style: context.responsiveHeadlineMedium),
          SizedBox(height: context.smallSpacing),
          Text(
            'Create your first fitness plan',
            style: context.responsiveBodyLarge.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: context.largeSpacing),
          ElevatedButton.icon(
            onPressed: _showAddPlanDialog,
            icon: Icon(
              Icons.add,
              color: Colors.white,
              size: ResponsiveHelper.getValue(
                context,
                mobile: 20.0,
                tablet: 22.0,
                desktop: 24.0,
              ),
            ),
            label: Text(
              'Create Plan',
              style: context.responsiveTitleLarge.copyWith(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getValue(
                  context,
                  mobile: 12.0,
                  tablet: 16.0,
                  desktop: 20.0,
                ),
                vertical: context.smallSpacing,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(
    BuildContext context,
    ThemeData theme,
    List<Course> courses,
  ) {
    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.all(
            ResponsiveHelper.getValue(
              context,
              mobile: 16.0,
              tablet: 20.0,
              desktop: 24.0,
            ),
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getValue(
                  context,
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
                horizontal: ResponsiveHelper.getValue(
                  context,
                  mobile: 8.0,
                  tablet: 12.0,
                  desktop: 16.0,
                ),
              ),
              child: _buildPlanCard(context, theme, course),
            );
          },
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: _showAddPlanDialog,
            backgroundColor: theme.primaryColor,
            tooltip: 'Add New Fitness Plan',
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: ResponsiveHelper.getValue(
                context,
                mobile: 24.0,
                tablet: 26.0,
                desktop: 28.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, ThemeData theme, Course course) {
    String formattedDate = 'Date not available';
    if (course.createdAt != null) {
      formattedDate = DateFormat('MMM d, yyyy').format(course.createdAt!);
    }

    final enrolledPatients = course.enrolledStudents;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.mediumSpacing),
      ),
      elevation: ResponsiveHelper.getValue(
        context,
        mobile: 4.0,
        tablet: 6.0,
        desktop: 8.0,
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseLessonsScreen(courseId: course.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: ResponsiveHelper.getValue(
                context,
                mobile: 160.0,
                tablet: 200.0,
                desktop: 250.0,
              ),
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
                                size: ResponsiveHelper.getValue(
                                  context,
                                  mobile: 50.0,
                                  tablet: 60.0,
                                  desktop: 70.0,
                                ),
                                color: theme.primaryColor,
                              ),
                            ),
                      )
                      : Container(
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.fitness_center,
                          size: ResponsiveHelper.getValue(
                            context,
                            mobile: 50.0,
                            tablet: 60.0,
                            desktop: 70.0,
                          ),
                          color: theme.primaryColor,
                        ),
                      ),
            ),
            Padding(
              padding: EdgeInsets.all(
                ResponsiveHelper.getValue(
                  context,
                  mobile: 8.0,
                  tablet: 12.0,
                  desktop: 16.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title.isNotEmpty ? course.title : 'Untitled Plan',
                    style: context.responsiveTitleLarge,
                  ),
                  SizedBox(height: context.smallSpacing),
                  Text(
                    course.description.isNotEmpty
                        ? course.description
                        : 'No description',
                    style: context.responsiveBodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.mediumSpacing),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: ResponsiveHelper.getValue(
                          context,
                          mobile: 16.0,
                          tablet: 18.0,
                          desktop: 20.0,
                        ),
                        color: theme.primaryColor,
                      ),
                      SizedBox(width: context.smallSpacing / 2),
                      Text(
                        '${enrolledPatients.length} Patients',
                        style: context.responsiveBodyMedium.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(width: context.mediumSpacing),
                      Icon(
                        Icons.calendar_today,
                        size: ResponsiveHelper.getValue(
                          context,
                          mobile: 16.0,
                          tablet: 18.0,
                          desktop: 20.0,
                        ),
                        color: theme.primaryColor,
                      ),
                      SizedBox(width: context.smallSpacing / 2),
                      Text(
                        formattedDate,
                        style: context.responsiveBodyMedium.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.mediumSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      CourseLessonsScreen(courseId: course.id),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.edit,
                          color: theme.primaryColor,
                          size: ResponsiveHelper.getValue(
                            context,
                            mobile: 16.0,
                            tablet: 18.0,
                            desktop: 20.0,
                          ),
                        ),
                        label: Text(
                          'Manage',
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              context.smallSpacing,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: ResponsiveHelper.getValue(
                            context,
                            mobile: 20.0,
                            tablet: 22.0,
                            desktop: 24.0,
                          ),
                        ),
                        onPressed:
                            () => _showDeleteConfirmation(
                              context,
                              theme,
                              course.id,
                            ),
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

  void _showDeleteConfirmation(
    BuildContext context,
    ThemeData theme,
    String planId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.mediumSpacing),
          ),
          title: Text(
            'Delete Fitness Plan',
            style: context.responsiveHeadlineMedium.copyWith(
              color: theme.primaryColor,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this fitness plan? This action cannot be undone.',
            style: context.responsiveBodyLarge.copyWith(
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: context.responsiveBodyLarge.copyWith(
                  color: theme.primaryColor,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: context.responsiveBodyLarge.copyWith(color: Colors.red),
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
