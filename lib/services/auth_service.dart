import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:test_project/services/cloudinary_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.message}')));
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

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );

          // Navigate to profile setup for new users
          Navigator.pushReplacementNamed(context, '/profileSetup');
        } else {
          // Existing user - update last login
          await _firestore.collection('users').doc(user.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged in successfully!')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.message}')),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully!')),
        );
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

  // Sign Out
  Future<void> signOut(BuildContext context) async {
    try {
      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await _auth.signOut().then(
        (value) => {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Log Out Successfully'))),
          Navigator.pushReplacementNamed(context, '/login'),
        },
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign out failed: ${e.message}')));
    }
  }

  // Upload Profile Photo
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
      // Upload to Cloudinary
      final String? imageUrl = await _cloudinaryService.uploadToCloudinary(
        filePath,
        dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '',
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
      print('Error fetching user data: $e');
      return null;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User is not logged in')));
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data saved successfully')),
      );

      // Navigate based on role
      if (role == 'Doctor') {
        Navigator.of(context).pushReplacementNamed('/doctorDashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/patientDashboard');
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

  // Reset Password
  Future<bool> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      return false;
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      print('Error sending email verification: $e');
    }
  }
}
