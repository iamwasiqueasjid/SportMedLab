// lib/screens/student_dashboard.dart
import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Handle logout
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [_buildHeader(), Expanded(child: _buildCourseTabs())],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'My Courses'),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'All Courses',
          ),
        ],
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.indigo.withOpacity(0.1),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 40, color: Colors.indigo),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, Student',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Find your next learning adventure',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Available Courses'),
              Tab(text: 'My Enrolled Courses'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildAvailableCourses(), _buildEnrolledCourses()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCourses() {
    // Dummy course data
    final courses = [
      {
        'title': 'Introduction to Flutter',
        'tutor': 'John Smith',
        'enrolled': 42,
        'image': null,
      },
      {
        'title': 'Advanced Firebase',
        'tutor': 'Jane Doe',
        'enrolled': 28,
        'image': null,
      },
      {
        'title': 'UI/UX Design Basics',
        'tutor': 'Alex Johnson',
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
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildEnrolledCourses() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Enrolled Courses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Enroll in courses to see them here',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Browse Courses'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            color: Colors.indigo.withOpacity(0.2),
            width: double.infinity,
            child: Center(
              child: Icon(Icons.school, size: 40, color: Colors.indigo),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'By ${course['tutor']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${course['enrolled']} students',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    minimumSize: Size(double.infinity, 30),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('Enroll Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
