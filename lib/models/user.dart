import 'package:cloud_firestore/cloud_firestore.dart';

abstract class User {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  // Convert object to Firestore-compatible map
  Map<String, dynamic> toMap();

  // Factory method to create User from Firestore data
  factory User.fromMap(Map<String, dynamic> data, String uid) {
    final String role =
        data['role'] ?? 'Patient'; // Default to Patient if role is missing
    if (role == 'Doctor') {
      return Doctor.fromMap(data, uid);
    } else {
      return Patient.fromMap(data, uid);
    }
  }
}

class Doctor extends User {
  Doctor({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
         uid: uid,
         email: email,
         displayName: displayName,
         photoURL: photoURL,
         role: 'Doctor',
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory Doctor.fromMap(Map<String, dynamic> data, String uid) {
    return Doctor(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class Patient extends User {
  final double weight;
  final double height;
  final String gender;
  final String dateOfBirth;

  Patient({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    required this.weight,
    required this.height,
    required this.gender,
    required this.dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
         uid: uid,
         email: email,
         displayName: displayName,
         photoURL: photoURL,
         role: 'Patient',
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory Patient.fromMap(Map<String, dynamic> data, String uid) {
    return Patient(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      height: (data['height'] as num?)?.toDouble() ?? 0.0,
      gender: data['gender'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
      'weight': weight,
      'height': height,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
