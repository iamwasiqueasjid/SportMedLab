import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test_project/models/course.dart'; // Import Course and Lesson models
import 'package:test_project/models/lesson.dart'; // Import Course and Lesson models
import 'package:test_project/models/user.dart';
import 'package:test_project/services/auth_service.dart';
import 'package:test_project/services/cloudinary_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'dart:io';

import 'package:test_project/widgets/app_message_notifier.dart';

class DatabaseService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final AuthService _authService = AuthService();

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

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
      AppNotifier.show(
        context,
        'User is not logged in',
        type: MessageType.warning,
      );
      return false;
    }

    // Check if user is a Doctor
    final userData = await _authService.fetchUserData();
    if (userData == null || userData.role != 'Doctor') {
      AppNotifier.show(
        context,
        'Only doctors can create courses',
        type: MessageType.error,
      );
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

      // Create course model
      final course = Course(
        id: '', // ID will be set by Firestore
        title: title,
        description: description,
        coverImageUrl: coverImageUrl ?? '',
        tutorId: user.uid,
        // createdAt: DateTime.now(),
        // updatedAt: DateTime.now(),
        enrolledStudents: [],
        subjects: subjects,
        enrolledCount: 0,
      );

      // Create course document in Firestore
      await _firestore.collection('courses').add(course.toMap());

      AppNotifier.show(
        context,
        'Course created successfully',
        type: MessageType.success,
      );

      return true;
    } catch (error) {
      AppNotifier.show(
        context,
        'Failed to create course: $error',
        type: MessageType.error,
      );
      return false;
    }
  }

  // Get tutor courses with real-time updates
  Stream<List<Course>> fetchTutorCoursesRealTime() {
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
                // Debug: Log the type of createdAt
                print(
                  'Document ${doc.id} createdAt type: ${data['createdAt'].runtimeType}',
                );
                return Course.fromMap(data, doc.id);
              }).toList();
          // Sort courses by createdAt (descending)
          courses.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return courses;
        });
  }

  // Get all courses (for students)
  Stream<List<Course>> fetchAllCoursesRealTime() {
    return _firestore.collection('courses').snapshots().map((snapshot) {
      var courses =
          snapshot.docs
              .map((doc) => Course.fromMap(doc.data(), doc.id))
              .toList();
      // Sort courses by createdAt (descending)
      // courses.sort((a, b) {
      //   if (a.createdAt == null) return 1;
      //   if (b.createdAt == null) return -1;
      //   return b.createdAt!.compareTo(a.createdAt!);
      // });
      return courses;
    });
  }

  // Get course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('courses').doc(courseId).get();
      if (doc.exists) {
        return Course.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
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
      // Upload new image if provided
      String? coverImageUrl;
      if (imageFile != null) {
        coverImageUrl = await _cloudinaryService.uploadToCloudinary(
          imageFile.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
      }

      // Create updated course model
      final course = Course(
        id: courseId,
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
        tutorId: '', // Will not update tutorId
        subjects: subjects,
      );

      await _firestore
          .collection('courses')
          .doc(courseId)
          .update(course.toMap());
      AppNotifier.show(
        context,
        'Course updated successfully',
        type: MessageType.success,
      );
      return true;
    } catch (error) {
      AppNotifier.show(
        context,
        'Failed to update course: $error',
        type: MessageType.error,
      );
      return false;
    }
  }

  // Delete a course
  Future<bool> deleteCourse(String courseId, BuildContext context) async {
    try {
      // Delete all lessons in the course
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
      await batch.commit();
      AppNotifier.show(
        context,
        'Course deleted successfully',
        type: MessageType.success,
      );
      return true;
    } catch (e) {
      AppNotifier.show(
        context,
        'Failed to delete course: $e',
        type: MessageType.error,
      );
      return false;
    }
  }

  // LESSON MANAGEMENT METHODS

  // Get lessons for a course
  Stream<List<Lesson>> fetchLessonsForCourse(String courseId) {
    return _firestore
        .collection('lessons')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
          var lessons =
              snapshot.docs
                  .map((doc) => Lesson.fromMap(doc.data(), doc.id))
                  .toList();
          // Sort lessons by order
          lessons.sort((a, b) => a.order.compareTo(b.order));
          return lessons;
        });
  }

  // Get lesson by ID
  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('lessons').doc(lessonId).get();
      if (doc.exists) {
        return Lesson.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
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

      // Get all lessons to determine order
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('lessons')
              .where('courseId', isEqualTo: courseId)
              .get();
      int newOrder = 0;
      if (querySnapshot.docs.isNotEmpty) {
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

      // Create lesson model
      final lesson = Lesson(
        id: '', // ID will be set by Firestore
        courseId: courseId,
        title: title,
        contentType: contentType,
        content: content,
        contentUrl: fileUrl,
        order: newOrder,
      );

      // Create lesson document
      await _firestore.collection('lessons').add(lesson.toMap());
      AppNotifier.show(
        context,
        'Lesson created successfully',
        type: MessageType.success,
      );
      return true;
    } catch (e) {
      AppNotifier.show(
        context,
        'Failed to create lesson: $e',
        type: MessageType.error,
      );
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
      // Upload new file if provided
      String? fileUrl;
      if (file != null && (contentType == 'image' || contentType == 'pdf')) {
        fileUrl = await _cloudinaryService.uploadToCloudinary(
          file.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
      }

      // Create updated lesson model
      final lesson = Lesson(
        id: lessonId,
        courseId: '', // Will not update courseId
        title: title,
        contentType: contentType,
        content: content,
        contentUrl: fileUrl,
      );

      await _firestore
          .collection('lessons')
          .doc(lessonId)
          .update(lesson.toMap());
      AppNotifier.show(
        context,
        'Lesson updated successfully',
        type: MessageType.success,
      );
      return true;
    } catch (e) {
      AppNotifier.show(
        context,
        'Failed to update lesson: $e',
        type: MessageType.error,
      );
      return false;
    }
  }

  // Delete a lesson
  Future<bool> deleteLesson(String lessonId, BuildContext context) async {
    try {
      await _firestore.collection('lessons').doc(lessonId).delete();
      AppNotifier.show(
        context,
        'Lesson deleted successfully',
        type: MessageType.success,
      );
      return true;
    } catch (e) {
      AppNotifier.show(
        context,
        'Failed to delete lesson: $e',
        type: MessageType.error,
      );
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
      AppNotifier.show(
        context,
        'User is not logged in',
        type: MessageType.warning,
      );
      return false;
    }

    try {
      DocumentSnapshot courseDoc =
          await _firestore.collection('courses').doc(courseId).get();
      if (courseDoc.exists) {
        final course = Course.fromMap(
          courseDoc.data() as Map<String, dynamic>,
          courseDoc.id,
        );
        if (course.enrolledStudents.contains(user.uid)) {
          AppNotifier.show(
            context,
            'Already enrolled in this course',
            type: MessageType.info,
          );
          return false;
        }

        await _firestore.collection('courses').doc(courseId).update({
          'enrolledStudents': FieldValue.arrayUnion([user.uid]),
          'enrolledCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppNotifier.show(
          context,
          'Successfully enrolled in course!',
          type: MessageType.success,
        );
        return true;
      }
      return false;
    } catch (e) {
      AppNotifier.show(
        context,
        'Failed to enroll in course: $e',
        type: MessageType.error,
      );
      return false;
    }
  }

  // Get enrolled courses for student
  Stream<List<Course>> fetchEnrolledCoursesRealTime() {
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
              snapshot.docs
                  .map((doc) => Course.fromMap(doc.data(), doc.id))
                  .toList();
          // Sort courses by updatedAt (descending)
          courses.sort((a, b) {
            if (a.updatedAt == null) return 1;
            if (b.updatedAt == null) return -1;
            return b.updatedAt!.compareTo(a.updatedAt!);
          });
          return courses;
        });
  }
}
