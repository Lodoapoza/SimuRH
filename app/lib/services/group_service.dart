import 'package:simurh/services/db_service.dart';
import 'package:simurh/models/group_model.dart';

class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  Future<Group> createGroup(String name, int simulationId) async {
    final db = await DbService().database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('groups_table', {
      'simulation_id': simulationId,
      'name': name,
      'created_at': now,
      'updated_at': now,
    });
    return Group(
      id: id.toString(),
      simulationId: simulationId.toString(),
      name: name,
    );
  }

  Future<List<Group>> getGroups(int simulationId) async {
    final db = await DbService().database;
    final rows = await db.query('groups_table',
        where: 'simulation_id = ?',
        whereArgs: [simulationId],
        orderBy: 'name ASC');
    final groups = <Group>[];
    for (final row in rows) {
      final members = await getMembers(row['id'] as int);
      groups.add(Group(
        id: row['id'].toString(),
        simulationId: simulationId.toString(),
        name: row['name'] as String,
        members: members,
      ));
    }
    return groups;
  }

  Future<void> updateGroupName(int groupId, String name) async {
    final db = await DbService().database;
    await db.update('groups_table',
        {'name': name, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [groupId]);
  }

  Future<void> deleteGroup(int groupId) async {
    final db = await DbService().database;
    await db.delete('group_members', where: 'group_id = ?', whereArgs: [groupId]);
    await db.delete('groups_table', where: 'id = ?', whereArgs: [groupId]);
  }

  Future<void> addMember(int groupId, String studentName) async {
    final db = await DbService().database;
    await db.insert('group_members', {
      'group_id': groupId,
      'student_name': studentName,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Member>> getMembers(int groupId) async {
    final db = await DbService().database;
    final rows = await db.query('group_members',
        where: 'group_id = ?', whereArgs: [groupId]);
    return rows.map((r) => Member(
      id: r['id'].toString(),
      name: r['student_name'] as String,
    )).toList();
  }

  Future<void> removeMember(int memberId) async {
    final db = await DbService().database;
    await db.delete('group_members', where: 'id = ?', whereArgs: [memberId]);
  }

  Future<void> addMembersBulk(int groupId, List<String> names) async {
    for (final name in names) {
      await addMember(groupId, name);
    }
  }
}
