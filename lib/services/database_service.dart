import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test_project/models/course.dart';
import 'package:test_project/models/lesson.dart';
import 'package:test_project/services/auth/auth_service.dart';
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
      await _firestore.collection('lessons').doc(lessonId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // COURSE MANAGEMENT METHODS
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
      String? coverImageUrl;
      if (imageFile != null) {
        coverImageUrl = await _cloudinaryService.uploadToCloudinary(
          imageFile.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
      } else {
        coverImageUrl = dotenv.env['COURSE_DEFAULT_IMAGE'] ?? '';
      }

      final course = Course(
        id: '',
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
        tutorId: user.uid,
        enrolledStudents: [],
        subjects: subjects,
        enrolledCount: 0,
      );

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
                return Course.fromMap(data, doc.id);
              }).toList();
          courses.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return courses;
        });
  }

  Stream<List<Course>> fetchAllCoursesRealTime() {
    return _firestore.collection('courses').snapshots().map((snapshot) {
      var courses =
          snapshot.docs
              .map((doc) => Course.fromMap(doc.data(), doc.id))
              .toList();
      return courses;
    });
  }

  Stream<List<Course>> fetchAvailableCoursesRealTime() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore.collection('courses').snapshots().asyncMap((
      snapshot,
    ) async {
      final enrolledCoursesSnapshot =
          await _firestore
              .collection('courses')
              .where('enrolledStudents', arrayContains: user.uid)
              .get();
      final enrolledCourseIds =
          enrolledCoursesSnapshot.docs.map((doc) => doc.id).toList();

      return snapshot.docs
          .map((doc) => Course.fromMap(doc.data(), doc.id))
          .where((course) => !enrolledCourseIds.contains(course.id))
          .toList();
    });
  }

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

  Future<bool> updateCourse({
    required String courseId,
    required String title,
    required String description,
    File? imageFile,
    List<String> subjects = const [],
    required BuildContext context,
  }) async {
    try {
      String? coverImageUrl;
      if (imageFile != null) {
        coverImageUrl = await _cloudinaryService.uploadToCloudinary(
          imageFile.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
      }

      final course = Course(
        id: courseId,
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
        tutorId: '',
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

  Future<bool> deleteCourse(String courseId, BuildContext context) async {
    try {
      final lessonsQuery =
          await _firestore
              .collection('lessons')
              .where('courseId', isEqualTo: courseId)
              .get();
      final batch = _firestore.batch();
      for (var doc in lessonsQuery.docs) {
        batch.delete(doc.reference);
      }
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
          lessons.sort((a, b) => a.order.compareTo(b.order));
          return lessons;
        });
  }

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

  Future<bool> createLesson({
    required String courseId,
    required String title,
    required String contentType,
    required String content,
    File? file,
    String? youtubeUrl, // New parameter
    required BuildContext context,
  }) async {
    try {
      String? fileUrl;
      if (file != null && (contentType == 'image' || contentType == 'pdf')) {
        fileUrl = await _cloudinaryService.uploadToCloudinary(
          file.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
      }

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

      final lesson = Lesson(
        id: '',
        courseId: courseId,
        title: title,
        contentType: contentType,
        content: content,
        contentUrl: fileUrl,
        youtubeUrl: youtubeUrl, // Include YouTube URL
        order: newOrder,
      );

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

  Future<bool> updateLesson({
    required String lessonId,
    required String title,
    required String contentType,
    required String content,
    File? file,
    required BuildContext context,
  }) async {
    try {
      String? fileUrl;
      if (file != null && (contentType == 'image' || contentType == 'pdf')) {
        fileUrl = await _cloudinaryService.uploadToCloudinary(
          file.path,
          dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
        );
      }

      final lesson = Lesson(
        id: lessonId,
        courseId: '',
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
          courses.sort((a, b) {
            if (a.updatedAt == null) return 1;
            if (b.updatedAt == null) return -1;
            return b.updatedAt!.compareTo(a.updatedAt!);
          });
          return courses;
        });
  }

  // CHAT MANAGEMENT METHODS

  /// Initiates a chat between a patient and a doctor by email
  Future<String?> initiateChat({
    required String patientId,
    required String doctorEmail,
    required String initialMessage,
    required BuildContext context,
  }) async {
    try {
      // Look up doctor by email
      final doctorQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: doctorEmail)
              .where('role', isEqualTo: 'Doctor')
              .limit(1)
              .get();

      if (doctorQuery.docs.isEmpty) {
        AppNotifier.show(
          context,
          'No doctor found with email $doctorEmail',
          type: MessageType.error,
        );
        return null;
      }

      final doctorId = doctorQuery.docs.first.id;
      final chatId = '${patientId}_$doctorId';

      // Check if chat already exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        // Create new chat
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [patientId, doctorId],
          'lastMessage': initialMessage,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': patientId,
        });

        // Add initial message
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
              'senderId': patientId,
              'receiverId': doctorId,
              'message': initialMessage,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
      } else {
        // Add message to existing chat
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
              'senderId': patientId,
              'receiverId': doctorId,
              'message': initialMessage,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });

        // Update last message
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': initialMessage,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': patientId,
        });
      }

      return chatId;
    } catch (e) {
      AppNotifier.show(
        context,
        'Error initiating chat: $e',
        type: MessageType.error,
      );
      return null;
    }
  }

  /// Sends a message in an existing chat
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    required BuildContext context,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });
      return true;
    } catch (e) {
      AppNotifier.show(
        context,
        'Error sending message: $e',
        type: MessageType.error,
      );
      return false;
    }
  }

  /// Streams all chats for a user
  Stream<List<Map<String, dynamic>>> fetchUserChats(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'chatId': doc.id,
                'participants': List<String>.from(data['participants'] ?? []),
                'lastMessage': data['lastMessage'] ?? '',
                'lastMessageTimestamp':
                    (data['lastMessageTimestamp'] as Timestamp?)?.toDate(),
                'lastMessageSenderId': data['lastMessageSenderId'] ?? '',
              };
            }).toList();
          })
          .handleError((e) {
            throw e; // Rethrow to trigger snapshot.hasError in StreamBuilder
          });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Streams messages for a specific chat
  Stream<List<Map<String, dynamic>>> fetchChatMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'messageId': doc.id,
                'senderId': data['senderId'],
                'receiverId': data['receiverId'],
                'message': data['message'],
                'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
                'isRead': data['isRead'] ?? false,
              };
            }).toList();
          });
    } catch (e) {
      return Stream.error(e);
    }
  }

  /// Marks messages as read
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final messages =
          await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('receiverId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in messages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {}
  }

  /// Fetches user details by ID
  Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Streams all doctors for chat initiation
  Stream<List<Map<String, dynamic>>> fetchDoctors() {
    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'Doctor')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'displayName': data['displayName'] ?? 'Unknown',
                'email': data['email'] ?? '',
                'photoURL': data['photoURL'] as String?,
              };
            }).toList();
          });
    } catch (e) {
      return Stream.error(e);
    }
  }
}
