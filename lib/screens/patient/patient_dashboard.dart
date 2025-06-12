import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/widgets/custom_drawer.dart';
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
      backgroundColor: Colors.white, // Match LoginScreen
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
        ), // Ensures hamburger icon is visible
        title: Text('Patient Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _authService.signOut(context),
          ),
        ],
      ),
      drawer: CustomDrawer(
        userName: _userName,
        photoUrl: _photoUrl,
        role: 'Patient',
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
                children: [_buildHeader(), Expanded(child: _buildPlanTabs())],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'My Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'All Plans',
          ),
        ],
        selectedItemColor: theme.primaryColor, // Match LoginScreen
        unselectedItemColor: Colors.grey[600], // Match LoginScreen
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white, // Match LoginScreen
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      color: theme.primaryColor, // Match DoctorDashboard
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : AssetImage('assets/images/avatar.png') as ImageProvider,
            backgroundColor: Colors.grey[100], // Match LoginScreen
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
                  color: Colors.black, // Match LoginScreen
                ),
              ),
              Text(
                'Explore your fitness journey',
                style: TextStyle(color: Colors.grey[600]), // Match LoginScreen
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTabs() {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: theme.primaryColor, // Match LoginScreen
            unselectedLabelColor: Colors.grey[600], // Match LoginScreen
            indicatorColor: theme.primaryColor, // Match LoginScreen
            tabs: [
              Tab(text: 'Available Plans'),
              Tab(text: 'My Enrolled Plans'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildAvailablePlans(), _buildEnrolledPlans()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlans() {
    // final theme = Theme.of(context);
    // Dummy plan data (replace with Firestore data)
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
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildEnrolledPlans() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: Colors.grey[600], // Match LoginScreen
          ),
          SizedBox(height: 16),
          Text(
            'No Enrolled Plans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Match LoginScreen
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Enroll in plans to see them here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600], // Match LoginScreen
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to available plans tab or screen
              DefaultTabController.of(context).animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor, // Match LoginScreen
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Match LoginScreen
              ),
            ),
            child: Text(
              'Browse Plans',
              style: TextStyle(color: Colors.white), // Match LoginScreen
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match LoginScreen
      ),
      elevation: 4,
      color: Colors.white, // Match LoginScreen
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            color: Colors.grey[100], // Match LoginScreen
            width: double.infinity,
            child: Center(
              child: Icon(
                Icons.fitness_center,
                size: 40,
                color: theme.primaryColor, // Match LoginScreen
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
                    color: Colors.black, // Match LoginScreen
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'By ${plan['doctor']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600], // Match LoginScreen
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: theme.primaryColor, // Match LoginScreen
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${plan['enrolled']} patients',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor, // Match LoginScreen
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement enroll functionality
                    AppNotifier.show(
                      context,
                      'Enrollment not implemented',
                      type: MessageType.error,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor, // Match LoginScreen
                    minimumSize: Size(double.infinity, 30),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Match LoginScreen
                    ),
                  ),
                  child: Text(
                    'Enroll Now',
                    style: TextStyle(color: Colors.white), // Match LoginScreen
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
