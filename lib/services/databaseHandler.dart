// lib/services/databaseService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_project/services/cloudinaryServices.dart';
import 'package:test_project/services/gemini_service.dart';
import 'package:test_project/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  // final GeminiService _geminiService = GeminiService();

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

  // AUTH METHODS
  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logged in successfully!')));

        // Check user role and navigate to appropriate screen
        final userData = await fetchUserData();
        if (userData != null && userData['role'] == 'Tutor') {
          Navigator.pushReplacementNamed(context, '/tutorDashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/studentDashboard');
        }
        return true;
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.message}')));
      return false;
    }
    return false;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User created successfully!')));
        Navigator.pushNamed(context, '/profileSetup');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign up failed: ${e.message}')));
      return false;
    }
    return false;
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut().then(
        (value) => {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Log Out Successfully'))),
          Navigator.pushReplacementNamed(context, '/login'),
        },
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign out failed: ${e.message}')));
    }
  }

  Future<String?> uploadProfilePhoto({
    required String filePath,
    required BuildContext context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User is not logged in')));
      return null;
    }

    try {
      print('Starting upload to Cloudinary...');
      print('Upload preset: ${AppConstants.cloudinaryUploadPreset}');

      // Upload to Cloudinary
      final CloudinaryService cloudinaryService = CloudinaryService();
      final String? imageUrl = await cloudinaryService.uploadImage(
        filePath,
        AppConstants.cloudinaryUploadPreset,
        folder: 'EdTech/Users',
      );

      print('Cloudinary upload complete, URL: $imageUrl');

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // First check if the document exists
          DocumentSnapshot docSnapshot =
              await _firestore.collection('users').doc(user.uid).get();

          if (docSnapshot.exists) {
            // If document exists, update it
            await _firestore.collection('users').doc(user.uid).update({
              'photoURL': imageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            // If document doesn't exist, create it with set()
            await _firestore.collection('users').doc(user.uid).set({
              'photoURL': imageUrl,
              'email': user.email,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
            ),
          );

          return imageUrl;
        } catch (firestoreError) {
          print('Firestore error: $firestoreError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving photo URL: $firestoreError')),
          );
          // Still return the URL even if Firestore update failed
          return imageUrl;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile photo')),
        );
        return null;
      }
    } catch (e) {
      print('Profile photo upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
      return null;
    }
  }

  // Check the user role
  Future<String?> getUserRole() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          return userData['role'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // FIRESTORE USER DATA METHODS

  // Fetch user data from Firestore
  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          return userDoc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Save profile data to Firestore
  Future<bool> saveProfileData({
    required String Name,
    required String Role,
    String? PhotoURL,
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
      // Create the data map
      Map<String, dynamic> userData = {
        'displayName': Name,
        'email': user.email,
        'role': Role,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add photoURL if it's provided and not empty
      if (PhotoURL != null && PhotoURL.isNotEmpty) {
        userData['photoURL'] = PhotoURL;
      }

      // Check if this is a new user
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Add createdAt for new users
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Use set with merge option to handle both new and existing documents
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data saved successfully')),
      );

      // Navigate based on role
      if (Role == 'Tutor') {
        Navigator.of(context).pushReplacementNamed('/tutorDashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/studentDashboard');
      }

      return true;
    } catch (error) {
      print('Error saving profile data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile data: $error')),
      );
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
        coverImageUrl = await _cloudinaryService.uploadImage(
          imageFile.path,
          AppConstants.cloudinaryUploadPreset,
          folder: 'EdTech/Courses',
          fileName: 'course_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Create course document in Firestore
      DocumentReference courseRef = await _firestore.collection('courses').add({
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

  // Add these methods to your DatabaseService class

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
        fileUrl = await _cloudinaryService.uploadImage(
          file.path,
          AppConstants.cloudinaryUploadPreset,
          folder: 'EdTech/Lessons/${contentType}s',
          fileName: '${contentType}_${DateTime.now().millisecondsSinceEpoch}',
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

      // Generate AI content for text lessons
      // String summary = '';
      // List<Map<String, String>> flashcards = [];

      // if (contentType == 'text' && content.isNotEmpty) {
      //   // Show a processing message
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Generating AI summary...')),
      //   );

      //   // Generate summary
      //   summary = await _geminiService.generateSummary(content);

      //   // Generate flashcards for longer content
      //   if (content.length > 100) {
      //     flashcards = await _geminiService.generateFlashcards(content);
      //   }
      // }

      // Create the lesson document
      DocumentReference docRef = await _firestore.collection('lessons').add({
        'courseId': courseId,
        'title': title,
        'contentType': contentType,
        'content': content,
        'contentUrl': fileUrl ?? '',
        // 'summary': summary,
        // 'flashcards': flashcards,
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

  // // Get lessons for a course (ordered by lesson order)
  // Stream<List<Map<String, dynamic>>> fetchLessonsForCourse(String courseId) {
  //   return _firestore
  //       .collection('lessons')
  //       .where('courseId', isEqualTo: courseId)
  //       .orderBy('order', descending: false)
  //       .snapshots()
  //       .map((snapshot) {
  //         return snapshot.docs.map((doc) {
  //           final data = doc.data();
  //           data['id'] = doc.id;
  //           return data;
  //         }).toList();
  //       });
  // }

  // // Delete a lesson
  // Future<bool> deleteLesson(String lessonId, BuildContext context) async {
  //   try {
  //     await _firestore.collection('lessons').doc(lessonId).delete();

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Lesson deleted successfully')),
  //     );

  //     return true;
  //   } catch (e) {
  //     print('Error deleting lesson: $e');
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Failed to delete lesson: $e')));
  //     return false;
  //   }
  // }
}
