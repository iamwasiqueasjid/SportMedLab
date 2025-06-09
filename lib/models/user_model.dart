class UserModel {
  final String uid;
  final String email;
  final bool isAdmin;

  UserModel({required this.uid, required this.email, required this.isAdmin});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'isAdmin': isAdmin};
  }
}
