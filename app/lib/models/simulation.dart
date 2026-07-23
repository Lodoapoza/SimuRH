import 'dart:convert';

class Simulation {
  final String id;
  final String professorId;
  final String establishmentId;
  final String code;
  final String title;
  final String context;
  final List<String> objectives;
  final int durationDays;
  final int maxGroups;
  final List<GradingCriterion> gradingCriteria;
  final String status; // draft/active/closed
  final DateTime createdAt;
  final String professorName;
  final int groupCount;
  final int submissionCount;
  final List<SimFile> files;

  Simulation({
    required this.id,
    required this.professorId,
    required this.establishmentId,
    required this.code,
    required this.title,
    required this.context,
    required this.objectives,
    required this.durationDays,
    required this.maxGroups,
    required this.gradingCriteria,
    required this.status,
    required this.createdAt,
    required this.professorName,
    required this.groupCount,
    required this.submissionCount,
    required this.files,
  });

  factory Simulation.fromJson(Map<String, dynamic> json) {
    return Simulation(
      id: json['id'] as String,
      professorId: json['professorId'] as String,
      establishmentId: json['establishmentId'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      context: json['context'] as String,
      objectives: List<String>.from(json['objectives'] as List),
      durationDays: json['durationDays'] as int,
      maxGroups: json['maxGroups'] as int,
      gradingCriteria: List<GradingCriterion>.from(
          (json['gradingCriteria'] as List).map((e) => GradingCriterion.fromJson(e))),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      professorName: json['professorName'] as String,
      groupCount: json['groupCount'] as int,
      submissionCount: json['submissionCount'] as int,
      files: List<SimFile>.from(
          (json['files'] as List).map((e) => SimFile.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professorId': professorId,
      'establishmentId': establishmentId,
      'code': code,
      'title': title,
      'context': context,
      'objectives': objectives,
      'durationDays': durationDays,
      'maxGroups': maxGroups,
      'gradingCriteria': gradingCriteria.map((e) => e.toJson()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'professorName': professorName,
      'groupCount': groupCount,
      'submissionCount': submissionCount,
      'files': files.map((e) => e.toJson()).toList(),
    };
  }
}

class GradingCriterion {
  final String name;
  final double maxScore;
  final double coefficient;

  GradingCriterion({
    required this.name,
    required this.maxScore,
    required this.coefficient,
  });

  factory GradingCriterion.fromJson(Map<String, dynamic> json) {
    return GradingCriterion(
      name: json['name'] as String,
      maxScore: (json['maxScore'] as num).toDouble(),
      coefficient: (json['coefficient'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'maxScore': maxScore,
      'coefficient': coefficient,
    };
  }
}

class SimFile {
  final String id;
  final String originalName;
  final String fileType;
  final int fileSize;

  SimFile({
    required this.id,
    required this.originalName,
    required this.fileType,
    required this.fileSize,
  });

  factory SimFile.fromJson(Map<String, dynamic> json) {
    return SimFile(
      id: json['id'] as String,
      originalName: json['originalName'] as String,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalName': originalName,
      'fileType': fileType,
      'fileSize': fileSize,
    };
  }
}