import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart';
import 'package:simurh/services/local_server_service.dart';

class LocalServerRoutes {
  final LocalServerService _server = LocalServerService();

  Router get router {
    final r = Router();

    // Middleware d'authentification
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

    // Routes publiques
    r.get('/api/health', (shelf.Request req) {
      return shelf.Response.ok('{"status": "ok", "version": "1.0.0"}',
        headers: {'Content-Type': 'application/json'});
    });

    // Routes protégées (à implémenter dans Phase 3B)
    r.get('/api/simulations', _authMiddleware((req) async {
      return shelf.Response.ok('[]',
        headers: {'Content-Type': 'application/json'});
    }));

    r.get('/api/groups/<simId>', _authMiddleware((req, simId) async {
      return shelf.Response.ok('[]',
        headers: {'Content-Type': 'application/json'});
    }));

    r.post('/api/submissions', _authMiddleware((req) async {
      return shelf.Response.ok('{"status": "received"}',
        headers: {'Content-Type': 'application/json'});
    }));

    return r;
  }
}
