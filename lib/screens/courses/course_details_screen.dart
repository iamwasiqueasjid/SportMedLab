// lib/screens/course_details_screen.dart
import 'package:flutter/material.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Course Details - $courseId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Course ID: $courseId'),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}
