import 'dart:convert';

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
    required this.leaderId,
    required this.leaderName,
    required this.createdAt,
    required this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      simulationId: json['simulationId'] as String,
      name: json['name'] as String,
      leaderId: json['leaderId'] as String,
      leaderName: json['leaderName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      members: List<Member>.from(
          (json['members'] as List).map((e) => Member.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'simulationId': simulationId,
      'name': name,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'createdAt': createdAt.toIso8601String(),
      'members': members.map((e) => e.toJson()).toList(),
    };
  }
}

class Member {
  final String id;
  final String name;
  final String email;
  final bool isLeader;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.isLeader,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isLeader: json['isLeader'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isLeader': isLeader,
    };
  }
}