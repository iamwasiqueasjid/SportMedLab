import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/widgets/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';

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
        title: Text('Patient Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _authService.signOut(context),
          ),
        ],
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
                children: [
                  _buildHeader(context),
                  Expanded(child: _buildPlanTabs(context)),
                ],
              ),
      bottomNavigationBar: CustomBottomNavBar(
        currentRoute: '/patientDashboard',
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      color: theme.primaryColor,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : AssetImage('assets/images/avatar.png') as ImageProvider,
            backgroundColor: Colors.grey[100],
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${_userName ?? 'Patient'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Explore your fitness journey',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTabs(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: theme.primaryColor,
            tabs: [
              Tab(text: 'Available Plans'),
              Tab(text: 'My Enrolled Plans'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailablePlans(context),
                _buildEnrolledPlans(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlans(BuildContext context) {
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

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(context, plan);
      },
    );
  }

  Widget _buildEnrolledPlans(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          SizedBox(height: 16),
          Text(
            'No Enrolled Plans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Enroll in plans to see them here',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              DefaultTabController.of(context).animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Browse Plans', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            color: Colors.grey[100],
            width: double.infinity,
            child: Center(
              child: Icon(
                Icons.fitness_center,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'By ${plan['doctor']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: theme.primaryColor),
                    SizedBox(width: 4),
                    Text(
                      '${plan['enrolled']} patients',
                      style: TextStyle(fontSize: 12, color: theme.primaryColor),
                    ),
                  ],
                ),
                SizedBox(height: 8),
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
                    minimumSize: Size(double.infinity, 30),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Enroll Now',
                    style: TextStyle(color: Colors.white),
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
