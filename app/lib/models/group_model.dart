class Member {
  final String id;
  final String name;
  final String email;
  final bool isLeader;

  Member({
    required this.id,
    required this.name,
    this.email = '',
    this.isLeader = false,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id']?.toString() ?? '',
    name: json['student_name'] as String? ?? json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    isLeader: json['isLeader'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_name': name,
    'email': email,
    'isLeader': isLeader,
  };
}

class Group {
  final String id;
  final String simulationId;
  final String name;
  final String leaderId;
  final String leaderName;
  final DateTime createdAt;
  final List<Member> members;

  Group({
    required this.id,
    required this.simulationId,
    required this.name,
    this.leaderId = '',
    this.leaderName = '',
    DateTime? createdAt,
    this.members = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id']?.toString() ?? '',
    simulationId: json['simulation_id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    leaderId: json['leaderId']?.toString() ?? '',
    leaderName: json['leaderName'] as String? ?? '',
    members: (json['members'] as List<dynamic>?)
            ?.map((m) => Member.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'simulation_id': simulationId,
    'name': name,
    'leaderId': leaderId,
    'leaderName': leaderName,
    'members': members.map((m) => m.toJson()).toList(),
  };
}