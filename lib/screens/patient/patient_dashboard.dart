import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/models/course.dart';
import 'package:test_project/screens/chat/chat_list_screen.dart';
import 'package:test_project/screens/courses/course_details_screen.dart';
import 'package:test_project/screens/courses/course_lesson_screen.dart';
import 'package:test_project/screens/blogs/blog_list.dart';
import 'package:test_project/screens/profile/edit_profile.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/services/database_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';
import 'package:test_project/utils/responsive_widget.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:flutter/material.dart';
import 'package:test_project/workout_pose/exercise_selection_screen.dart';
import 'package:intl/intl.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  PatientDashboardState createState() => PatientDashboardState();
}

class PatientDashboardState extends State<PatientDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  String? _userName;
  String? _photoUrl;
  bool _isLoading = true;
  late TabController _courseTabController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _courseTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _courseTabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Patient Dashboard',
          style: context.responsiveTitleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
      length: 5,
      child: Column(
        children: [
          Expanded(
            child: TabBarView(
              children: [
                _buildCoursesTabs(context, theme),
                BlogList(),
                ExerciseSelectionWidget(),
                ChatListWidget(),
                ProfileWidget(),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(
              ResponsiveHelper.getValue(
                context,
                mobile: 8.0,
                tablet: 12.0,
                desktop: 16.0,
              ),
            ),
            decoration: BoxDecoration(
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
                    Icons.fitness_center_outlined,
                    size: ResponsiveHelper.getValue(
                      context,
                      mobile: 20.0,
                      tablet: 22.0,
                      desktop: 24.0,
                    ),
                  ),
                  text: 'Workout',
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      height: ResponsiveHelper.getValue(
        context,
        mobile: 80.0,
        tablet: 100.0,
        desktop: 120.0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getValue(
          context,
          mobile: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
        vertical: ResponsiveHelper.getValue(
          context,
          mobile: 12.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
      ),
      color: theme.primaryColor,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.0),
            ),
            child: CircleAvatar(
              radius: ResponsiveHelper.getValue(
                context,
                mobile: 22.0,
                tablet: 25.0,
                desktop: 30.0,
              ),
              backgroundImage:
                  _photoUrl != null
                      ? NetworkImage(_photoUrl!)
                      : const AssetImage('assets/images/avatar.png')
                          as ImageProvider,
              backgroundColor: Colors.grey[100],
              onBackgroundImageError: (_, __) => const Icon(Icons.person),
            ),
          ),
          SizedBox(width: context.smallSpacing),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, ${_userName ?? 'Patient'}',
                  style: context.responsiveHeadlineMedium.copyWith(
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Explore your fitness journey',
                  style: context.responsiveBodyMedium.copyWith(
                    color: Colors.grey[400],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCoursesTabs(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildHeader(context, theme),
        TabBar(
          controller: _courseTabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(text: 'Available Plans'),
            Tab(text: 'My Enrolled Plans'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _courseTabController,
            children: [
              _buildAvailablePlans(context, theme),
              _buildEnrolledPlans(context, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailablePlans(BuildContext context, ThemeData theme) {
    return StreamBuilder<List<Course>>(
      stream: _databaseService.fetchAvailableCoursesRealTime(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitDoubleBounce(
              color: theme.primaryColor,
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
              style: context.responsiveTitleLarge,
            ),
          );
        }

        final courses = snapshot.data ?? [];

        if (courses.isEmpty) {
          return Center(
            child: SingleChildScrollView(
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
                  Text(
                    'No Available Plans',
                    style: context.responsiveHeadlineMedium,
                  ),
                  SizedBox(height: context.smallSpacing),
                  Text(
                    'No fitness plans available at the moment',
                    style: context.responsiveBodyLarge.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(
            ResponsiveHelper.getValue(
              context,
              mobile: 8.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.getValue(
              context,
              mobile: 2,
              tablet: 3,
              desktop: 4,
            ),
            childAspectRatio: ResponsiveHelper.getValue(
              context,
              mobile: 0.65,
              tablet: 0.75,
              desktop: 0.85,
            ),
            crossAxisSpacing: context.smallSpacing,
            mainAxisSpacing: context.smallSpacing,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            return _buildPlanCard(context, theme, courses[index]);
          },
        );
      },
    );
  }

  Widget _buildEnrolledPlans(BuildContext context, ThemeData theme) {
    return StreamBuilder<List<Course>>(
      stream: _databaseService.fetchEnrolledCoursesRealTime(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitDoubleBounce(
              color: theme.primaryColor,
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
            'Error loading enrolled courses: ${snapshot.error}',
            type: MessageType.error,
          );
          return Center(
            child: Text(
              'Error loading enrolled courses',
              style: context.responsiveTitleLarge,
            ),
          );
        }

        final courses = snapshot.data ?? [];

        if (courses.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Text(
                    'No Enrolled Plans',
                    style: context.responsiveHeadlineMedium,
                  ),
                  SizedBox(height: context.smallSpacing),
                  Text(
                    'Enroll in plans to see them here',
                    style: context.responsiveBodyLarge.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: context.largeSpacing),
                  ElevatedButton(
                    onPressed: () {
                      _courseTabController.animateTo(0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.mediumSpacing * 1.5,
                        vertical: context.smallSpacing,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.smallSpacing,
                        ),
                      ),
                    ),
                    child: Text(
                      'Browse Plans',
                      style: context.responsiveTitleLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(
            ResponsiveHelper.getValue(
              context,
              mobile: 8.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.getValue(
              context,
              mobile: 2,
              tablet: 3,
              desktop: 4,
            ),
            childAspectRatio: ResponsiveHelper.getValue(
              context,
              mobile: 0.65,
              tablet: 0.75,
              desktop: 0.85,
            ),
            crossAxisSpacing: context.smallSpacing,
            mainAxisSpacing: context.smallSpacing,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            return _buildPlanCard(
              context,
              theme,
              courses[index],
              isEnrolled: true,
            );
          },
        );
      },
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    ThemeData theme,
    Course course, {
    bool isEnrolled = false,
  }) {
    String formattedDate = 'Date not available';
    if (course.createdAt != null) {
      formattedDate = DateFormat('MMM d, yyyy').format(course.createdAt!);
    }

    return Card(
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
          if (isEnrolled) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseLessonsScreen(courseId: course.id),
              ),
            );
          }
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: ResponsiveHelper.getValue(
              context,
              mobile: 200.0,
              tablet: 250.0,
              desktop: 300.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 2,
                child: SizedBox(
                  width: double.infinity,
                  child:
                      course.coverImageUrl != null &&
                              course.coverImageUrl!.isNotEmpty
                          ? Image.network(
                            course.coverImageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (
                              BuildContext context,
                              Widget child,
                              ImageChunkEvent? loadingProgress,
                            ) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Center(
                                child: SpinKitCircle(
                                  color: theme.primaryColor,
                                  size: ResponsiveHelper.getValue(
                                    context,
                                    mobile: 30.0,
                                    tablet: 40.0,
                                    desktop: 50.0,
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: ResponsiveHelper.getValue(
                                      context,
                                      mobile: 40.0,
                                      tablet: 50.0,
                                      desktop: 60.0,
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
                                mobile: 40.0,
                                tablet: 50.0,
                                desktop: 60.0,
                              ),
                              color: theme.primaryColor,
                            ),
                          ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getValue(
                      context,
                      mobile: 4.0,
                      tablet: 6.0,
                      desktop: 8.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title.isNotEmpty
                                  ? course.title
                                  : 'Untitled Plan',
                              style: context.responsiveTitleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: context.smallSpacing / 2),
                            FutureBuilder<Map<String, dynamic>?>(
                              future: _databaseService.fetchUserDetails(
                                course.tutorId,
                              ),
                              builder: (context, snapshot) {
                                String doctorName = 'Unknown Doctor';
                                if (snapshot.hasData && snapshot.data != null) {
                                  doctorName =
                                      snapshot.data!['displayName'] ??
                                      'Unknown Doctor';
                                }
                                return Text(
                                  'By $doctorName',
                                  style: context.responsiveBodyMedium.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            SizedBox(height: context.smallSpacing),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: ResponsiveHelper.getValue(
                                    context,
                                    mobile: 14.0,
                                    tablet: 16.0,
                                    desktop: 18.0,
                                  ),
                                  color: theme.primaryColor,
                                ),
                                SizedBox(width: context.smallSpacing / 2),
                                Text(
                                  '${course.enrolledCount} patients',
                                  style: context.responsiveBodyMedium.copyWith(
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: context.smallSpacing),
                            Text(
                              formattedDate,
                              style: context.responsiveBodyMedium.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.smallSpacing),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isEnrolled
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CourseLessonsScreen(
                                              courseId: course.id,
                                            ),
                                      ),
                                    );
                                  }
                                  : () {
                                    CourseDetailsScreen.show(
                                      context: context,
                                      courseId: course.id,
                                      onEnrollSuccess: () {
                                        setState(() {});
                                        _courseTabController.animateTo(1);
                                      },
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            minimumSize: Size(
                              double.infinity,
                              ResponsiveHelper.getValue(
                                context,
                                mobile: 30.0,
                                tablet: 35.0,
                                desktop: 40.0,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: context.smallSpacing,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.smallSpacing,
                              ),
                            ),
                          ),
                          child: Text(
                            isEnrolled ? 'View Lessons' : 'Enroll Now',
                            style: context.responsiveBodyLarge.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
