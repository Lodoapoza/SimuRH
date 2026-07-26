import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SyncClient {
  static final SyncClient _instance = SyncClient._internal();
  factory SyncClient() => _instance;
  SyncClient._internal();

  String? _serverIp;
  int? _serverPort;
  String? _token;

  bool get isConnected => _serverIp != null && _token != null;

  /// Lit les infos de connexion depuis SharedPreferences
  Future<void> loadConnection() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString('simurh_server_ip');
    _serverPort = prefs.getInt('simurh_server_port') ?? 
        int.tryParse(prefs.getString('simurh_server_port') ?? '');
    _token = prefs.getString('simurh_server_token');
  }

  /// Sauvegarde les infos de connexion
  Future<void> saveConnection(String ip, int port, String token) async {
    _serverIp = ip;
    _serverPort = port;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('simurh_server_ip', ip);
    await prefs.setInt('simurh_server_port', port);
    await prefs.setString('simurh_server_token', token);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Uri _url(String path) {
    if (_serverIp == null || _serverPort == null) {
      throw Exception('SyncClient: non connecté');
    }
    return Uri.parse('http://$_serverIp:$_serverPort$path');
  }

  /// Vérifie la connectivité
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(_url('/api/health'),
          headers: _headers).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Récupère toutes les simulations
  Future<List<Map<String, dynamic>>> fetchSimulations() async {
    try {
      final response = await http.get(_url('/api/simulations'),
          headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Récupère une simulation par son ID
  Future<Map<String, dynamic>?> fetchSimulation(int simId) async {
    try {
      final response = await http.get(_url('/api/simulations/$simId'),
          headers: _headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Récupère les groupes d'une simulation (ou tous)
  Future<List<Map<String, dynamic>>> fetchGroups({int? simulationId}) async {
    try {
      final query = simulationId != null ? '?simulationId=$simulationId' : '';
      final response = await http.get(_url('/api/groups$query'),
          headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Envoie une soumission
  Future<bool> postSubmission(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        _url('/api/submissions'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Récupère les soumissions (optionnellement filtrées par groupe)
  Future<List<Map<String, dynamic>>> fetchSubmissions({int? groupId}) async {
    try {
      final query = groupId != null ? '?groupId=$groupId' : '';
      final response = await http.get(_url('/api/submissions$query'),
          headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Récupère les évaluations
  Future<List<Map<String, dynamic>>> fetchEvaluations({int? groupId}) async {
    try {
      final query = groupId != null ? '?groupId=$groupId' : '';
      final response = await http.get(_url('/api/evaluations$query'),
          headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Efface les infos de connexion
  Future<void> disconnect() async {
    _serverIp = null;
    _serverPort = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('simurh_server_ip');
    await prefs.remove('simurh_server_port');
    await prefs.remove('simurh_server_token');
  }
}
