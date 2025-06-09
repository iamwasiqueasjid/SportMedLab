import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test_project/services/cloudinary_service.dart';
import 'dart:io';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Update lesson with AI-generated content
  Future<bool> updateLessonWithAIContent({
    required String lessonId,
    required String content,
  }) async {
    try {
      // Generate summary and flashcards
      // final summary = await _geminiService.generateSummary(content);
      // final flashcards = await _geminiService.generateFlashcards(content);

      // Update the lesson in Firestore
      await _firestore.collection('lessons').doc(lessonId).update({
        // 'summary': summary,
        // 'flashcards': flashcards,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating lesson with AI content: $e');
      return false;
    }
  }

  // COURSE MANAGEMENT METHODS

  // Create a new course
  Future<bool> createCourse({
    required String title,
    required String description,
    File? imageFile,
    List<String> subjects = const [],
    required BuildContext context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User is not logged in')));
      return false;
    }

    try {
      // Upload course cover image if provided
      String? coverImageUrl;

      if (imageFile != null) {
        coverImageUrl = await _cloudinaryService.uploadToCloudinary(
          imageFile.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
      }

      // Create course document in Firestore
      // DocumentReference courseRef = await _firestore.collection('courses').add({
      await _firestore.collection('courses').add({
        'title': title,
        'description': description,
        'coverImageUrl': coverImageUrl ?? '',
        'tutorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'enrolledStudents': [],
        'subjects': subjects,
        'enrolledCount': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course created successfully')),
      );

      return true;
    } catch (error) {
      print('Error creating course: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create course: $error')),
      );
      return false;
    }
  }

  // Get tutor courses with real-time updates
  Stream<List<Map<String, dynamic>>> fetchTutorCoursesRealTime() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('courses')
        .where('tutorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          var courses =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();

          // Sort courses by createdAt (descending) on the client side
          courses.sort((a, b) {
            if (a['createdAt'] == null) return 1;
            if (b['createdAt'] == null) return -1;

            Timestamp aTimestamp = a['createdAt'] as Timestamp;
            Timestamp bTimestamp = b['createdAt'] as Timestamp;

            return bTimestamp.compareTo(aTimestamp); // Descending order
          });

          return courses;
        });
  }

  // Get all courses (for students)
  Stream<List<Map<String, dynamic>>> fetchAllCoursesRealTime() {
    return _firestore.collection('courses').snapshots().map((snapshot) {
      var courses =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      // Sort courses by createdAt (descending)
      courses.sort((a, b) {
        if (a['createdAt'] == null) return 1;
        if (b['createdAt'] == null) return -1;

        Timestamp aTimestamp = a['createdAt'] as Timestamp;
        Timestamp bTimestamp = b['createdAt'] as Timestamp;

        return bTimestamp.compareTo(aTimestamp);
      });

      return courses;
    });
  }

  // Get course by ID
  Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    try {
      print("Fetching course with ID: $courseId");
      DocumentSnapshot doc =
          await _firestore.collection('courses').doc(courseId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }

      print("Course not found with ID: $courseId");
      return null;
    } catch (e) {
      print('Error getting course by ID: $e');
      return null;
    }
  }

  // Update course
  Future<bool> updateCourse({
    required String courseId,
    required String title,
    required String description,
    File? imageFile,
    List<String> subjects = const [],
    required BuildContext context,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'title': title,
        'description': description,
        'subjects': subjects,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Upload new image if provided
      if (imageFile != null) {
        String? coverImageUrl = await _cloudinaryService.uploadToCloudinary(
          imageFile.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
        updateData['coverImageUrl'] = coverImageUrl ?? '';
      }

      await _firestore.collection('courses').doc(courseId).update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course updated successfully')),
      );

      return true;
    } catch (error) {
      print('Error updating course: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update course: $error')),
      );
      return false;
    }
  }

  // Delete a course
  Future<bool> deleteCourse(String courseId, BuildContext context) async {
    try {
      // First delete all lessons in the course
      final lessonsQuery =
          await _firestore
              .collection('lessons')
              .where('courseId', isEqualTo: courseId)
              .get();

      final batch = _firestore.batch();

      for (var doc in lessonsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete the course document
      batch.delete(_firestore.collection('courses').doc(courseId));

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully')),
      );

      return true;
    } catch (e) {
      print('Error deleting course: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete course: $e')));
      return false;
    }
  }

  // LESSON MANAGEMENT METHODS

  // Get lessons for a course
  Stream<List<Map<String, dynamic>>> fetchLessonsForCourse(String courseId) {
    print("Starting stream for lessons with courseId: $courseId");
    return _firestore
        .collection('lessons')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
          var lessons =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();

          // Sort lessons by order (client-side sorting to avoid needing an index)
          lessons.sort((a, b) {
            int orderA = a['order'] ?? 0;
            int orderB = b['order'] ?? 0;
            return orderA.compareTo(orderB);
          });

          print("Fetched ${lessons.length} lessons for course $courseId");
          return lessons;
        });
  }

  // Get lesson by ID
  Future<Map<String, dynamic>?> getLessonById(String lessonId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('lessons').doc(lessonId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }

      return null;
    } catch (e) {
      print('Error getting lesson by ID: $e');
      return null;
    }
  }

  // Create a new lesson
  Future<bool> createLesson({
    required String courseId,
    required String title,
    required String contentType,
    required String content,
    File? file,
    required BuildContext context,
  }) async {
    try {
      // Upload file if provided
      String? fileUrl;

      if (file != null && (contentType == 'image' || contentType == 'pdf')) {
        fileUrl = await _cloudinaryService.uploadToCloudinary(
          file.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
      }

      // Get all lessons for this course to determine the order
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('lessons')
              .where('courseId', isEqualTo: courseId)
              .get();

      // Calculate the next order number client-side
      int newOrder = 0;

      if (querySnapshot.docs.isNotEmpty) {
        // Find the highest order number
        newOrder =
            querySnapshot.docs
                .map(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['order'] as int? ??
                      0,
                )
                .reduce((max, value) => value > max ? value : max) +
            1;
      }

      // Create the lesson document
      DocumentReference docRef = await _firestore.collection('lessons').add({
        'courseId': courseId,
        'title': title,
        'contentType': contentType,
        'content': content,
        'contentUrl': fileUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'order': newOrder,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson created successfully')),
      );

      return true;
    } catch (e) {
      print('Error creating lesson: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create lesson: $e')));
      return false;
    }
  }

  // Update lesson
  Future<bool> updateLesson({
    required String lessonId,
    required String title,
    required String contentType,
    required String content,
    File? file,
    required BuildContext context,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'title': title,
        'contentType': contentType,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Upload new file if provided
      if (file != null && (contentType == 'image' || contentType == 'pdf')) {
        String? fileUrl = await _cloudinaryService.uploadToCloudinary(
          file.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
        updateData['contentUrl'] = fileUrl ?? '';
      }

      await _firestore.collection('lessons').doc(lessonId).update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson updated successfully')),
      );

      return true;
    } catch (e) {
      print('Error updating lesson: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update lesson: $e')));
      return false;
    }
  }

  // Delete a lesson
  Future<bool> deleteLesson(String lessonId, BuildContext context) async {
    try {
      await _firestore.collection('lessons').doc(lessonId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson deleted successfully')),
      );

      return true;
    } catch (e) {
      print('Error deleting lesson: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete lesson: $e')));
      return false;
    }
  }

  // ENROLLMENT METHODS

  // Enroll student in a course
  Future<bool> enrollInCourse({
    required String courseId,
    required BuildContext context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User is not logged in')));
      return false;
    }

    try {
      // Check if already enrolled
      DocumentSnapshot courseDoc =
          await _firestore.collection('courses').doc(courseId).get();

      if (courseDoc.exists) {
        Map<String, dynamic> courseData =
            courseDoc.data() as Map<String, dynamic>;
        List<dynamic> enrolledStudents = courseData['enrolledStudents'] ?? [];

        if (enrolledStudents.contains(user.uid)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already enrolled in this course')),
          );
          return false;
        }

        // Add student to enrolled list
        await _firestore.collection('courses').doc(courseId).update({
          'enrolledStudents': FieldValue.arrayUnion([user.uid]),
          'enrolledCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully enrolled in course!')),
        );

        return true;
      }
    } catch (e) {
      print('Error enrolling in course: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to enroll in course: $e')));
    }
    return false;
  }

  // Get enrolled courses for student
  Stream<List<Map<String, dynamic>>> fetchEnrolledCoursesRealTime() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('courses')
        .where('enrolledStudents', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
          var courses =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();

          // Sort courses by enrollment date (latest first)
          courses.sort((a, b) {
            if (a['updatedAt'] == null) return 1;
            if (b['updatedAt'] == null) return -1;

            Timestamp aTimestamp = a['updatedAt'] as Timestamp;
            Timestamp bTimestamp = b['updatedAt'] as Timestamp;

            return bTimestamp.compareTo(aTimestamp);
          });

          return courses;
        });
  }
}
