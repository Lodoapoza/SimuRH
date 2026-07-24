import 'dart:convert';

class Submission {
  final String id;
  final String groupId;
  final String simulationId;
  final String content;
  final String? filePath;
  final DateTime submittedAt;
  final DateTime? syncedAt;
  final String groupName;
  final String leaderName;
  final double totalScore;
  final String? comments;
  final Map<String, double> scores;
  final String status;

  Submission({
    required this.id,
    required this.groupId,
    required this.simulationId,
    required this.content,
    this.filePath,
    required this.submittedAt,
    this.syncedAt,
    required this.groupName,
    required this.leaderName,
    required this.totalScore,
    this.comments,
    required this.scores,
    this.status = 'submitted',
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      simulationId: json['simulationId'] as String,
      content: json['content'] as String,
      filePath: json['filePath'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      syncedAt: json['syncedAt'] != null ? DateTime.parse(json['syncedAt'] as String) : null,
      groupName: json['groupName'] as String,
      leaderName: json['leaderName'] as String,
      totalScore: (json['totalScore'] as num).toDouble(),
      comments: json['comments'] as String?,
      scores: Map<String, double>.from(json['scores'] as Map),
      status: json['status'] as String? ?? 'submitted',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'simulationId': simulationId,
      'content': content,
      'filePath': filePath,
      'submittedAt': submittedAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'groupName': groupName,
      'leaderName': leaderName,
      'totalScore': totalScore,
      'comments': comments,
      'scores': scores,
      'status': status,
    };
  }
}