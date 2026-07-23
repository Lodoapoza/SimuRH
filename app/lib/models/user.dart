import 'dart:convert';

class User {
  final String id;
  final String establishmentId;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final String role; // professor/student
  final String? apiToken;
  final String? establishmentName;
  final String? licenseStatus;

  User({
    required this.id,
    required this.establishmentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.role,
    this.apiToken,
    this.establishmentName,
    this.licenseStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      establishmentId: json['establishmentId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      passwordHash: json['passwordHash'] as String,
      role: json['role'] as String,
      apiToken: json['apiToken'] as String?,
      establishmentName: json['establishmentName'] as String?,
      licenseStatus: json['licenseStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'name': name,
      'email': email,
      'phone': phone,
      'passwordHash': passwordHash,
      'role': role,
      'apiToken': apiToken,
      'establishmentName': establishmentName,
      'licenseStatus': licenseStatus,
    };
  }
}