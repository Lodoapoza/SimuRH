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
  final String status;
  final DateTime createdAt;
  final String professorName;
  final int groupCount;
  final int decisionPeriods;
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
    required this.decisionPeriods,
    required this.submissionCount,
    required this.files,
  });

  factory Simulation.fromJson(Map<String, dynamic> json) {
    String _str(String key) => (json[key] as String?) ?? '';
    int _int(String key, {int def = 0}) =>
        json[key] is int ? json[key] as int : int.tryParse('${json[key] ?? def}') ?? def;
    List<String> _strList(String key) {
      final v = json[key];
      if (v is List) return List<String>.from(v);
      if (v is String) {
        try {
          final d = jsonDecode(v);
          if (d is List) return List<String>.from(d);
        } catch (_) {}
        return v.isEmpty ? [] : [v];
      }
      return [];
    }
    List<GradingCriterion> _criteria(String key) {
      final v = json[key];
      if (v is List) {
        return List<GradingCriterion>.from(
            v.map((e) => GradingCriterion.fromJson(e is Map<String, dynamic> ? e : {})));
      }
      if (v is String) {
        try {
          final d = jsonDecode(v);
          if (d is List) {
            return List<GradingCriterion>.from(
                d.map((e) => GradingCriterion.fromJson(e is Map<String, dynamic> ? e : {})));
          }
        } catch (_) {}
      }
      return [];
    }
    List<SimFile> _files(String key) {
      final v = json[key];
      if (v is List) {
        return List<SimFile>.from(
            v.map((e) => SimFile.fromJson(e is Map<String, dynamic> ? e : {})));
      }
      return [];
    }

    return Simulation(
      id: (json['id'] ?? '').toString(),
      professorId: _str('professorId'),
      establishmentId: _str('establishmentId'),
      code: _str('code'),
      title: _str('title'),
      context: _str('context'),
      objectives: _strList('objectives'),
      durationDays: _int('duration_days', def: 7),
      maxGroups: _int('max_groups', def: 5),
      gradingCriteria: _criteria('grading_criteria'),
      status: _str('status'),
      createdAt: _str('created_at').isNotEmpty
          ? DateTime.parse(_str('created_at'))
          : DateTime.now(),
      professorName: _str('professor_name'),
      groupCount: _int('group_count'),
      decisionPeriods: _int('decision_periods', def: 1),
      submissionCount: _int('submission_count'),
      files: _files('files'),
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
      'decisionPeriods': decisionPeriods,
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
      name: (json['name'] as String?) ?? '',
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 0.0,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
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
      id: (json['id'] ?? '').toString(),
      originalName: (json['originalName'] as String?) ?? '',
      fileType: (json['fileType'] as String?) ?? '',
      fileSize: (json['fileSize'] as int?) ?? 0,
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
