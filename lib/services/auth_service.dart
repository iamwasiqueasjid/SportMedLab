import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:test_project/services/cloudinary_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Login
  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        AppNotifier.show(
          context,
          'Logged in successfully!',
          type: MessageType.success,
        );

        // Check user role and navigate to appropriate screen
        final userData = await fetchUserData();
        if (userData != null && userData['role'] == 'Doctor') {
          Navigator.pushReplacementNamed(context, '/doctorDashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/patientDashboard');
        }
        return true;
      }
    } on FirebaseAuthException catch (e) {
      AppNotifier.show(
        context,
        'Login failed: ${e.message}',
        type: MessageType.error,
      );
      return false;
    }
    return false;
  }

  // Google Sign-In
  Future<bool> signInWithGoogle({required BuildContext context}) async {
    try {
      // Sign out from Google first to force account selection
      await _googleSignIn.signOut();

      // Trigger the authentication flow with account selection
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          // Create user document in Firestore for new users
          await _firestore.collection('users').doc(user.uid).set({
            'displayName': user.displayName ?? '',
            'email': user.email ?? '',
            'photoURL': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'authProvider': 'google',
          });
          AppNotifier.show(
            context,
            'Account created successfully!',
            type: MessageType.success,
          );

          // Navigate to profile setup for new users
          Navigator.pushReplacementNamed(context, '/profileSetup');
        } else {
          // Existing user - update last login
          await _firestore.collection('users').doc(user.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          AppNotifier.show(
            context,
            'Logged in successfully!',
            type: MessageType.success,
          );

          // Check user role and navigate to appropriate screen
          final userData = await fetchUserData();
          if (userData != null && userData['role'] == 'Doctor') {
            Navigator.pushReplacementNamed(context, '/doctorDashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/patientDashboard');
          }
        }

        return true;
      }
    } on FirebaseAuthException catch (e) {
      AppNotifier.show(
        context,
        'Google sign-in failed: ${e.message}',
        type: MessageType.error,
      );
      return false;
    } catch (e) {
      AppNotifier.show(
        context,
        'An error occurred: $e',
        type: MessageType.error,
      );
      return false;
    }
    return false;
  }

  // Email/Password Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        AppNotifier.show(
          context,
          'User created successfully!',
          type: MessageType.success,
        );
        Navigator.pushNamed(context, '/profileSetup');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      AppNotifier.show(
        context,
        'Sign up failed: ${e.message}',
        type: MessageType.error,
      );
      return false;
    }
    return false;
  }

  // Sign Out
  Future<void> signOut(BuildContext context) async {
    try {
      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await _auth.signOut().then(
        (value) => {
          AppNotifier.show(
            context,
            'Logged Out Successfully',
            type: MessageType.info,
          ),

          Navigator.pushReplacementNamed(context, '/login'),
        },
      );
    } on FirebaseAuthException catch (e) {
      AppNotifier.show(
        context,
        'Log out failed: ${e.message}',
        type: MessageType.error,
      );
    }
  }

  // Upload Profile Photo
  Future<String?> uploadProfilePhoto({
    required String filePath,
    required BuildContext context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppNotifier.show(
        context,
        'User is not Logged In',
        type: MessageType.warning,
      );
      return null;
    }

    try {
      // Upload to Cloudinary
      final String? imageUrl = await _cloudinaryService.uploadToCloudinary(
        filePath,
        dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '',
      );

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

          AppNotifier.show(
            context,
            'Profile photo updated successfully!',
            type: MessageType.success,
          );

          return imageUrl;
        } catch (firestoreError) {
          AppNotifier.show(
            context,
            'Error saving photo URL: $firestoreError',
            type: MessageType.error,
          );
          // Still return the URL even if Firestore update failed
          return imageUrl;
        }
      } else {
        AppNotifier.show(
          context,
          'Failed to upload profile photo',
          type: MessageType.error,
        );
        return null;
      }
    } catch (e) {
      AppNotifier.show(
        context,
        'Error uploading photo: $e',
        type: MessageType.error,
      );
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
      return null;
    }
  }

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
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Save profile data to Firestore
  Future<bool> saveProfileData({
    required String name,
    required String role,
    String? photoURL,
    required double weight,
    required String weightUnit,
    required double height,
    required String gender,
    required String dateOfBirth,
    required BuildContext context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppNotifier.show(
        context,
        'User is not Logged In',
        type: MessageType.warning,
      );
      return false;
    }

    try {
      // Create the data map with all profile fields
      Map<String, dynamic> userData = {
        'displayName': name,
        'email': user.email,
        'role': role,
        'weight': weight,
        'weightUnit': weightUnit,
        'height': height,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add photoURL if it's provided and not empty
      if (photoURL != null && photoURL.isNotEmpty) {
        userData['photoURL'] = photoURL;
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

      AppNotifier.show(
        context,
        'Profile data saved successfully',
        type: MessageType.success,
      );

      // Navigate based on role
      if (role == 'Doctor') {
        Navigator.of(context).pushReplacementNamed('/doctorDashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/patientDashboard');
      }

      return true;
    } catch (error) {
      AppNotifier.show(
        context,
        'Failed to save profile data: $error',
        type: MessageType.error,
      );
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppNotifier.show(
        context,
        'Password reset Email sent! \nCheck your inbox.',
        type: MessageType.success,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      AppNotifier.show(
        context,
        'Error sending Password reset Mail: ${e.message}',
        type: MessageType.error,
      );
      return false;
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}
