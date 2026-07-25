class LocalProfile {
  final int id;
  final String name;
  final String role;        // 'professor' | 'student'
  final int? groupId;       // null pour professeur
  final bool isActive;      // profil actuellement sélectionné
  final DateTime createdAt;

  LocalProfile({
    required this.id,
    required this.name,
    required this.role,
    this.groupId,
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'group_id': groupId,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory LocalProfile.fromMap(Map<String, dynamic> map) => LocalProfile(
    id: map['id'],
    name: map['name'],
    role: map['role'],
    groupId: map['group_id'],
    isActive: map['is_active'] == 1,
    createdAt: DateTime.parse(map['created_at']),
  );
}
