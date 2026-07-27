import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simurh/services/db_service.dart';

class Group {
  final int id;
  final int simulationId;
  final String name;
  final int? leaderId;
  final String createdAt;

  Group({
    required this.id,
    required this.simulationId,
    required this.name,
    this.leaderId,
    required this.createdAt,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as int,
      simulationId: map['simulation_id'] as int,
      name: map['name'] as String? ?? '',
      leaderId: map['leader_id'] as int?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}

class GroupNotifier extends StateNotifier<List<Group>> {
  final DbService _db = DbService();

  GroupNotifier() : super([]);

  Future<void> loadGroups({int? simulationId}) async {
    final rows = simulationId != null
        ? await _db.query('groups_table', where: 'simulation_id = ?', whereArgs: [simulationId])
        : await _db.query('groups_table');
    state = rows.map((r) => Group.fromMap(r)).toList();
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, List<Group>>((ref) {
  return GroupNotifier();
});
