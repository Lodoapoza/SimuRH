import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:network_info_plus/network_info_plus.dart';

class LocalServerService {
  static final LocalServerService _instance = LocalServerService._internal();
  factory LocalServerService() => _instance;
  LocalServerService._internal();

  HttpServer? _server;
  int _port = 8080;
  String _token = '';
  Router? _router;

  bool get isRunning => _server != null;
  int get port => _port;
  String get token => _token;
  Router get router => _router ?? Router();

  void setRouter(Router router) {
    _router = router;
  }

  Future<String?> getLocalIp() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      return ip;
    } catch (e) {
      return null;
    }
  }

  Future<bool> start({int port = 8080}) async {
    try {
      _port = port;
      _token = _generateToken();

      final router = _router ?? Router();

      final handler = const shelf.Pipeline()
          .addMiddleware(shelf.logRequests())
          .addHandler(router);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
      return true;
    } catch (e) {
      _server = null;
      return false;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  String _generateToken() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Vérifie si un token est valide
  bool isTokenValid(String? token) {
    return token == _token;
  }
}
