import 'dart:convert';

class RankingEntry {
  final String groupName;
  final double totalScore;
  final String? comments;
  final DateTime evaluatedAt;
  final int memberCount;
  final int rank;

  RankingEntry({
    required this.groupName,
    required this.totalScore,
    this.comments,
    required this.evaluatedAt,
    required this.memberCount,
    required this.rank,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      groupName: json['groupName'] as String,
      totalScore: (json['totalScore'] as num).toDouble(),
      comments: json['comments'] as String?,
      evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
      memberCount: json['memberCount'] as int,
      rank: json['rank'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupName': groupName,
      'totalScore': totalScore,
      'comments': comments,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'memberCount': memberCount,
      'rank': rank,
    };
  }
}