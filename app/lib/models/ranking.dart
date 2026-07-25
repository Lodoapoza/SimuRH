class RankingEntry {
  final String groupName;
  final double totalScore;
  final String? comments;
  final DateTime? evaluatedAt;
  final int memberCount;
  final int rank;

  RankingEntry({
    required this.groupName,
    required this.totalScore,
    this.comments,
    this.evaluatedAt,
    this.memberCount = 0,
    this.rank = 0,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
    groupName: json['groupName'] as String? ?? '',
    totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
    comments: json['comments'] as String?,
    memberCount: json['memberCount'] as int? ?? 0,
    rank: json['rank'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'groupName': groupName,
    'totalScore': totalScore,
    'comments': comments,
    'memberCount': memberCount,
    'rank': rank,
  };
}
