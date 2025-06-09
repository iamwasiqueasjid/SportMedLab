class PatientModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String disease;
  final String createdBy;
  final String createdAt;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.disease,
    required this.createdBy,
    required this.createdAt,
  });

  factory PatientModel.fromMap(String id, Map<String, dynamic> map) {
    return PatientModel(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      disease: map['disease'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'disease': disease,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}
