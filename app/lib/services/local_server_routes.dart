import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart';
import 'package:simurh/services/local_server_service.dart';
import 'package:simurh/services/db_service.dart';
import 'package:simurh/services/group_service.dart';

class LocalServerRoutes {
  final LocalServerService _server = LocalServerService();
  final DbService _db = DbService();
  final GroupService _groupService = GroupService();

  Router get router {
    final r = Router();

    shelf.Middleware _authMiddleware(shelf.Handler inner) {
      return (shelf.Request req) {
        final token = req.headers['authorization']?.replaceFirst('Bearer ', '');
        if (token == null || !_server.isTokenValid(token)) {
          return shelf.Response.unauthorized('{"error": "Non autorisé"}',
              headers: {'Content-Type': 'application/json'});
        }
        return inner(req);
      };
    }

    r.get('/api/health', (shelf.Request req) {
      return shelf.Response.ok(
          jsonEncode({'status': 'ok', 'version': '1.0.0'}),
          headers: {'Content-Type': 'application/json'});
    });

    r.get('/api/simulations', _authMiddleware((req) async {
      try {
        final sims = await _db.getCachedSimulations();
        return shelf.Response.ok(jsonEncode(sims),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return shelf.Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/simulations/<simId>', _authMiddleware((req, simId) async {
      try {
        final results = await _db.query('simulations',
            where: 'id = ?', whereArgs: [int.tryParse(simId) ?? 0]);
        if (results.isEmpty) {
          return shelf.Response.notFound('{"error": "Simulation not found"}',
              headers: {'Content-Type': 'application/json'});
        }
        return shelf.Response.ok(jsonEncode(results.first),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return shelf.Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/groups/<simId>', _authMiddleware((req, simId) async {
      try {
        final groups = await _groupService
            .getGroups(int.tryParse(simId) ?? 0);
        final data = groups.map((g) => {
          'id': g.id,
          'name': g.name,
          'member_count': g.members.length,
          'members': g.members.map((m) => {
            'id': m.id,
            'student_name': m.name,
          }).toList(),
        }).toList();
        return shelf.Response.ok(jsonEncode(data),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return shelf.Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.post('/api/submissions', _authMiddleware((req) async {
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
        return shelf.Response.ok(
            jsonEncode({'status': 'received', 'message': 'Soumission enregistrée'}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return shelf.Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/submissions', _authMiddleware((req) async {
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
        return shelf.Response.ok(jsonEncode(results),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return shelf.Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    r.get('/api/evaluations', _authMiddleware((req) async {
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
        return shelf.Response.ok(jsonEncode(results),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return shelf.Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: {'Content-Type': 'application/json'});
      }
    }));

    return r;
  }
}
