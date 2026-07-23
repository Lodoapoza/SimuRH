import 'dart:convert';

class Resource {
  final String id;
  final String professorId;
  final String establishmentId;
  final String title;
  final String description;
  final String filePath;
  final String fileType;
  final DateTime uploadedAt;
  final String professorName;

  Resource({
    required this.id,
    required this.professorId,
    required this.establishmentId,
    required this.title,
    required this.description,
    required this.filePath,
    required this.fileType,
    required this.uploadedAt,
    required this.professorName,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      professorId: json['professorId'] as String,
      establishmentId: json['establishmentId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      filePath: json['filePath'] as String,
      fileType: json['fileType'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      professorName: json['professorName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professorId': professorId,
      'establishmentId': establishmentId,
      'title': title,
      'description': description,
      'filePath': filePath,
      'fileType': fileType,
      'uploadedAt': uploadedAt.toIso8601String(),
      'professorName': professorName,
    };
  }
}