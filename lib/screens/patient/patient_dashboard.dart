import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';
import 'package:test_project/utils/responsive_widget.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:flutter/material.dart';
import 'package:test_project/workout_pose/exercise_selection_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  PatientDashboardState createState() => PatientDashboardState();
}

class PatientDashboardState extends State<PatientDashboard> {
  final AuthService _authService = AuthService();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: Text(
          'Patient Dashboard',
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
      case DeviceType.mobile:
      default:
        return _buildMobileLayout(context, theme);
    }
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Column(children: [Expanded(child: _buildPlanTabs(context, theme))]);
  }

  Widget _buildTabletLayout(BuildContext context, ThemeData theme) {
    return Padding(
      padding: context.horizontalPadding,
      child: Column(
        children: [Expanded(child: _buildPlanTabs(context, theme))],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: context.allPadding,
        child: Column(
          children: [Expanded(child: _buildPlanTabs(context, theme))],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: context.allPadding,
      color: theme.primaryColor,
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveHelper.getValue(
              context,
              mobile: 30.0,
              tablet: 40.0,
              desktop: 50.0,
            ),
            backgroundImage:
                _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : const AssetImage('assets/images/avatar.png')
                        as ImageProvider,
            backgroundColor: Colors.grey[100],
          ),
          SizedBox(width: context.mediumSpacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${_userName ?? 'Patient'}',
                style: context.responsiveHeadlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                'Explore your fitness journey',
                style: context.responsiveBodyMedium.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTabs(BuildContext context, ThemeData theme) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailablePlans(context, theme),
                _buildEnrolledPlans(context, theme),
                ExerciseSelectionWidget(),
                Center(
                  child: Text('Chats', style: context.responsiveTitleLarge),
                ),
                Center(
                  child: Text('Profile', style: context.responsiveTitleLarge),
                ),
              ],
            ),
          ),
          Container(
            margin: context.allPadding,
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
              labelStyle: context.responsiveBodyLarge,
              unselectedLabelStyle: context.responsiveBodyMedium,
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.dashboard_outlined,
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

  Widget _buildAvailablePlans(BuildContext context, ThemeData theme) {
    final plans = [
      {
        'title': 'Weight Loss Program',
        'doctor': 'Dr. John Smith',
        'enrolled': 42,
        'image': null,
      },
      {
        'title': 'Muscle Gain Plan',
        'doctor': 'Dr. Jane Doe',
        'enrolled': 28,
        'image': null,
      },
      {
        'title': 'Cardio Fitness',
        'doctor': 'Dr. Alex Johnson',
        'enrolled': 56,
        'image': null,
      },
    ];

    return Column(
      children: [
        _buildHeader(context, theme),
        Expanded(
          child: GridView.builder(
            padding: context.allPadding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveHelper.getValue(
                context,
                mobile: 2,
                tablet: 3,
                desktop: 4,
              ),
              childAspectRatio: ResponsiveHelper.getValue(
                context,
                mobile: 0.7,
                tablet: 0.8,
                desktop: 0.9,
              ),
              crossAxisSpacing: context.mediumSpacing,
              mainAxisSpacing: context.mediumSpacing,
            ),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _buildPlanCard(context, theme, plan);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnrolledPlans(BuildContext context, ThemeData theme) {
    return Center(
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
          Text('No Enrolled Plans', style: context.responsiveHeadlineMedium),
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
              DefaultTabController.of(context).animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: context.mediumSpacing * 1.5,
                vertical: context.smallSpacing,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.smallSpacing),
              ),
            ),
            child: Text(
              'Browse Plans',
              style: context.responsiveTitleLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> plan,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: ResponsiveHelper.getValue(
              context,
              mobile: 100.0,
              tablet: 120.0,
              desktop: 140.0,
            ),
            color: Colors.grey[100],
            width: double.infinity,
            child: Center(
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
          Padding(
            padding: EdgeInsets.all(context.smallSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['title'],
                  style: context.responsiveTitleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.smallSpacing / 2),
                Text(
                  'By ${plan['doctor']}',
                  style: context.responsiveBodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
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
                      '${plan['enrolled']} patients',
                      style: context.responsiveBodyMedium.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.smallSpacing),
                ElevatedButton(
                  onPressed: () {
                    AppNotifier.show(
                      context,
                      'Enrollment not implemented',
                      type: MessageType.error,
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
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.smallSpacing),
                    ),
                  ),
                  child: Text(
                    'Enroll Now',
                    style: context.responsiveBodyLarge.copyWith(
                      color: Colors.white,
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
}
