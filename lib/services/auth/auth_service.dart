import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/models/user.dart';
import 'package:test_project/services/cloudinary_service.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Login
  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
    required rememberMe,
  }) async {
    try {
      // Note: Removed setPersistence as it's not supported on mobile platforms
      // Store rememberMe in shared_preferences (already done in LoginScreen)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);

      final firebase_auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        AppNotifier.show(
          context,
          'Logged in successfully!',
          type: MessageType.success,
        );

        // Check user role and navigate to appropriate screen
        final userData = await fetchUserData();
        if (userData != null && userData.role == 'Doctor') {
          Navigator.pushReplacementNamed(context, '/doctorDashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/patientDashboard');
        }
        return true;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
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
  Future<bool> signInWithGoogle({
    required BuildContext context,
    bool rememberMe = true,
  }) async {
    try {
      // Store rememberMe in shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);

      // Sign out from Google first to force account selection
      await _googleSignIn.signOut();

      // Trigger the authentication flow with account selection
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppNotifier.show(
          context,
          'User canceled the Sign-In process.',
          type: MessageType.error,
        );
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential = await _auth
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          // Create a new Doctor or Patient based on default role
          final newUser = Patient(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoURL: user.photoURL,
            weight: 0.0, // Default weight, can be updated later
            height: 0.0, // Default height, can be updated later
            gender: '', // Default gender value, can be updated later
            dateOfBirth: '', // Default DOB value, can be updated later
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());

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
          if (userData != null && userData.role == 'Doctor') {
            Navigator.pushReplacementNamed(context, '/doctorDashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/patientDashboard');
          }
        }

        return true;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
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
      // Default to persistent session for sign-up
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true); // Default for new users

      final firebase_auth.UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        // Create a new Patient by default
        final newUser = Patient(
          uid: credential.user!.uid,
          email: email,
          displayName: '',
          weight: 0.0,
          height: 0.0,
          gender: '',
          dateOfBirth: '',
        );
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        AppNotifier.show(
          context,
          'User created successfully!',
          type: MessageType.success,
        );
        Navigator.pushNamed(context, '/profileSetup');
        return true;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
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
      // Clear rememberMe preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');

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
    } on firebase_auth.FirebaseAuthException catch (e) {
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
        dotenv.env['CLOUDINARY_CLOUD_PRESET'] ?? '',
      );
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update({
          'photoURL': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        AppNotifier.show(
          context,
          'Profile photo updated successfully!',
          type: MessageType.success,
        );
        return imageUrl;
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

  // Fetch user data
  Future<User?> fetchUserData() async {
    try {
      firebase_auth.User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          return User.fromMap(
            userDoc.data() as Map<String, dynamic>,
            currentUser.uid,
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    final userData = await fetchUserData();
    return userData?.role;
  }

  // Save profile data
  Future<bool> saveProfileData({
    required String name,
    required String role,
    String? photoURL,
    required double weight,
    required double height,
    required String gender,
    required String dateOfBirth,
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
      User userModel;
      if (role == 'Doctor') {
        userModel = Doctor(
          uid: user.uid,
          email: user.email ?? '',
          displayName: name,
          photoURL: photoURL,
          createdAt: user.metadata.creationTime,
          updatedAt: DateTime.now(),
        );
      } else {
        userModel = Patient(
          uid: user.uid,
          email: user.email ?? '',
          displayName: name,
          photoURL: photoURL,
          weight: weight,
          height: height,
          gender: gender,
          dateOfBirth: dateOfBirth,
          createdAt: user.metadata.creationTime,
          updatedAt: DateTime.now(),
        );
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap(), SetOptions(merge: true));

      AppNotifier.show(
        context,
        'Profile data saved successfully',
        type: MessageType.success,
      );

      Navigator.pushReplacementNamed(
        context,
        role == 'Doctor' ? '/doctorDashboard' : '/patientDashboard',
      );
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
      // First check if the email exists in our database
      final QuerySnapshot userQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      if (userQuery.docs.isEmpty) {
        AppNotifier.show(
          context,
          'No account found with this email address',
          type: MessageType.error,
        );
        return false;
      }

      // If email exists, send password reset email
      await _auth.sendPasswordResetEmail(email: email);
      AppNotifier.show(
        context,
        'Password reset email sent successfully!\nPlease check your inbox.',
        type: MessageType.success,
      );
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppNotifier.show(
        context,
        'Error sending Password reset Mail: ${e.message}',
        type: MessageType.error,
      );
      return false;
    } catch (e) {
      AppNotifier.show(
        context,
        'An error occurred while checking email: $e',
        type: MessageType.error,
      );
      return false;
    }
  }
}
