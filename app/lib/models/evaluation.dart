import 'dart:convert';

class Evaluation {
  final String id;
  final String submissionId;
  final String professorId;
  final Map<String, double> scores;
  final double totalScore;
  final String? comments;
  final DateTime evaluatedAt;

  Evaluation({
    required this.id,
    required this.submissionId,
    required this.professorId,
    required this.scores,
    required this.totalScore,
    this.comments,
    required this.evaluatedAt,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      id: json['id'] as String,
      submissionId: json['submissionId'] as String,
      professorId: json['professorId'] as String,
      scores: Map<String, double>.from(json['scores'] as Map),
      totalScore: (json['totalScore'] as num).toDouble(),
      comments: json['comments'] as String?,
      evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submissionId': submissionId,
      'professorId': professorId,
      'scores': scores,
      'totalScore': totalScore,
      'comments': comments,
      'evaluatedAt': evaluatedAt.toIso8601String(),
    };
  }
}