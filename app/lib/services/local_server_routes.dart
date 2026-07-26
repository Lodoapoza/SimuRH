import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:simurh/services/local_server_service.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/group_service.dart';
import 'package:simurh/services/license_service.dart';

class LocalServerRoutes {
  final LocalServerService _server = LocalServerService();
  final DbService _db = DbService();
  final GroupService _groupService = GroupService();

  Router get router {
    final r = Router();

    Middleware authMiddleware() {
      return (Handler inner) {
        return (Request req) async {
          final token = req.headers['authorization']?.replaceFirst('Bearer ', '');
          if (token == null || !_server.isTokenValid(token)) {
            return Response.unauthorized('{"error": "Non autorisé"}',
                headers: {'Content-Type': 'application/json'});
          }
          return await inner(req);
        };
      };
    }

    final auth = authMiddleware();

    r.get('/api/health', (Request req) async {
      final license = await LicenseService.getLicense();
      return Response.ok(
          jsonEncode({
            'status': 'ok',
            'version': '1.0.0',
            'etablissement': license?.etablissement ?? '',
            'token': _server.token,
          }),
          headers: {'Content-Type': 'application/json'});
    });

    r.get('/api/simulations', auth((Request req) async {
      try {
        final sims = await _db.getCachedSimulations();
        return Response.ok(jsonEncode(sims),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/simulations/<simId>', auth((Request req) async {
      final simId = req.params['simId']!;
      try {
        final results = await _db.query('simulations',
            where: 'id = ?', whereArgs: [int.tryParse(simId) ?? 0]);
        if (results.isEmpty) {
          return Response.notFound('{"error": "Not found"}',
              headers: {'Content-Type': 'application/json'});
        }
        return Response.ok(jsonEncode(results.first),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.post('/api/simulations', auth((Request req) async {
      try {
        final payload = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
        final id = await _db.insert('simulations', payload);
        return Response.ok(jsonEncode({'id': id}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.put('/api/simulations/<simId>', auth((Request req) async {
      try {
        final simId = req.params['simId']!;
        final payload = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
        await _db.update('simulations', payload,
            where: 'id = ?', whereArgs: [int.tryParse(simId) ?? 0]);
        return Response.ok(jsonEncode({'status': 'updated'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/groups/all', auth((Request req) async {
      try {
        final rows = await _db.query('groups_table');
        final data = <Map<String, dynamic>>[];
        for (final row in rows) {
          final gid = row['id'] as int;
          final members = await _db.query('group_members',
              where: 'group_id = ?', whereArgs: [gid]);
          data.add({
            'id': row['id'].toString(),
            'name': row['name'] as String,
            'simulation_id': row['simulation_id'],
            'member_count': members.length,
            'members': members.map((m) => {
              'id': m['id'].toString(),
              'student_name': m['student_name'] as String,
            }).toList(),
          });
        }
        return Response.ok(jsonEncode(data),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/groups', auth((Request req) async {
      try {
        final simulationId = req.url.queryParameters['simulationId'];
        if (simulationId != null) {
          final groups = await _groupService.getGroups(int.tryParse(simulationId) ?? 0);
          final data = groups.map((g) => {
            'id': g.id,
            'name': g.name,
            'member_count': g.members.length,
            'members': g.members.map((m) => {
              'id': m.id,
              'student_name': m.name,
            }).toList(),
          }).toList();
          return Response.ok(jsonEncode(data),
              headers: {'Content-Type': 'application/json'});
        }
        final rows = await _db.query('groups_table');
        final data = <Map<String, dynamic>>[];
        for (final row in rows) {
          final gid = row['id'] as int;
          final members = await _db.query('group_members',
              where: 'group_id = ?', whereArgs: [gid]);
          data.add({
            'id': row['id'].toString(),
            'name': row['name'] as String,
            'simulation_id': row['simulation_id'],
            'member_count': members.length,
            'members': members.map((m) => {
              'id': m['id'].toString(),
              'student_name': m['student_name'] as String,
            }).toList(),
          });
        }
        return Response.ok(jsonEncode(data),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.post('/api/groups', auth((Request req) async {
      try {
        final payload = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
        final group = await _groupService.createGroup(
            payload['name'] as String,
            int.tryParse('${payload['simulation_id']}') ?? 0);
        return Response.ok(jsonEncode({'id': group.id}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.put('/api/groups/<groupId>', auth((Request req) async {
      try {
        final groupId = int.tryParse(req.params['groupId']!) ?? 0;
        final payload = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
        await _groupService.updateGroupName(groupId, payload['name'] as String);
        return Response.ok(jsonEncode({'status': 'updated'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.delete('/api/groups/<groupId>', auth((Request req) async {
      try {
        final groupId = int.tryParse(req.params['groupId']!) ?? 0;
        await _groupService.deleteGroup(groupId);
        return Response.ok(jsonEncode({'status': 'deleted'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.post('/api/groups/<groupId>/members', auth((Request req) async {
      try {
        final groupId = int.tryParse(req.params['groupId']!) ?? 0;
        final payload = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
        await _groupService.addMember(groupId, payload['student_name'] as String);
        return Response.ok(jsonEncode({'status': 'added'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.delete('/api/groups/<groupId>/members/<memberId>', auth((Request req) async {
      try {
        final memberId = int.tryParse(req.params['memberId']!) ?? 0;
        await _groupService.removeMember(memberId);
        return Response.ok(jsonEncode({'status': 'removed'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.post('/api/submissions', auth((Request req) async {
      try {
        final payload = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
        final submission = {
          'simulation_id': payload['simulation_id'],
          'group_id': payload['group_id'],
          'content': payload['content'] ?? '',
          'status': 'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
          'is_pending_sync': 0,
        };
        await _db.insert('submissions', submission);
        return Response.ok(
            jsonEncode({'status': 'received', 'message': 'Soumission enregistrée'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/submissions', auth((Request req) async {
      try {
        final groupId = req.url.queryParameters['groupId'];
        List<Map<String, dynamic>> results;
        if (groupId != null) {
          results = await _db.query('submissions',
              where: 'group_id = ?',
              whereArgs: [int.tryParse(groupId) ?? 0]);
        } else {
          results = await _db.query('submissions');
        }
        return Response.ok(jsonEncode(results),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/evaluations', auth((Request req) async {
      try {
        final groupId = req.url.queryParameters['groupId'];
        List<Map<String, dynamic>> results;
        if (groupId != null) {
          results = await _db.query('evaluations',
              where: 'submission_id IN (SELECT id FROM submissions WHERE group_id = ?)',
              whereArgs: [int.tryParse(groupId) ?? 0]);
        } else {
          results = await _db.query('evaluations');
        }
        return Response.ok(jsonEncode(results),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    return r;
  }
}
