
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = 'https://simurh.glocal-innov.com/api';
  static const String _fallbackIp = '109.234.164.11';
  static const String _host = 'simurh.glocal-innov.com';
  static const Duration _timeout = Duration(seconds: 30);

  static String get baseUrl => _baseUrl;
  static String? _token;

  /// Initializes the API service by loading the token from SharedPreferences.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  /// Sets the authentication token.
  static void setToken(String? token) {
    _token = token;
    _saveToken(token);
  }

  static Future<void> _saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  static String? getToken() => _token;

  /// Builds common headers for API requests.
  Map<String, String> getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Détecte si une [SocketException] est une erreur DNS.
  bool _isDnsError(SocketException e) {
    return e.osError?.errorCode == 7 ||
        e.message.toLowerCase().contains('host lookup') ||
        e.message.toLowerCase().contains('nodename');
  }

  /// Vérifie si l'URL actuelle utilise le nom de domaine (pas le fallback IP).
  bool _isDomainUrl(String endpoint) {
    return endpoint.startsWith(_baseUrl);
  }

  /// Effectue une requête HTTP avec fallback DNS.
  /// Si le DNS ne résout pas le nom de domaine, on réessaie
  /// en HTTP direct avec l'IP et le header Host.
  Future<http.Response> _request(
    String method,
    String endpoint, {
    String? body,
    bool isUpload = false,
    String? filePath,
  }) async {
    Uri uri;
    Map<String, String> headers;

    uri = Uri.parse('$_baseUrl$endpoint');
    headers = getHeaders();

    try {
      return await _executeRequest(method, uri, headers,
          body: body, isUpload: isUpload, filePath: filePath);
    } on SocketException catch (e) {
      if (_isDnsError(e)) {
        // Fallback : IP directe en HTTP avec header Host
        final fallbackUri = Uri.parse('http://$_fallbackIp/api$endpoint');
        final fallbackHeaders = getHeaders();
        fallbackHeaders['Host'] = _host;

        return await _executeRequest(method, fallbackUri, fallbackHeaders,
            body: body, isUpload: isUpload, filePath: filePath);
      }
      rethrow;
    }
  }

  Future<http.Response> _executeRequest(
    String method,
    Uri uri,
    Map<String, String> headers, {
    String? body,
    bool isUpload = false,
    String? filePath,
  }) async {
    if (isUpload && filePath != null) {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send().timeout(_timeout);
      return http.Response.fromStream(streamedResponse);
    }

    switch (method) {
      case 'GET':
        return await http.get(uri, headers: headers).timeout(_timeout);
      case 'POST':
        return await http.post(uri, headers: headers, body: body)
            .timeout(_timeout);
      case 'PUT':
        return await http.put(uri, headers: headers, body: body)
            .timeout(_timeout);
      case 'DELETE':
        return await http.delete(uri, headers: headers).timeout(_timeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Handles HTTP responses, checking for errors and decoding JSON.
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw HttpException(errorBody['message'] ?? 'An unknown error occurred',
            uri: response.request?.url);
      } on FormatException {
        throw HttpException('Server error: ${response.statusCode}',
            uri: response.request?.url);
      } catch (e) {
        throw HttpException(
            'Request failed: ${response.statusCode} - ${response.body}',
            uri: response.request?.url);
      }
    }
  }

  /// Performs a GET request to the API.
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _request('GET', endpoint);
    return _handleResponse(response);
  }

  /// Performs a GET request expecting a list of data from the API.
  Future<List<Map<String, dynamic>>> getList(String endpoint) async {
    final response = await _request('GET', endpoint);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw HttpException(errorBody['message'] ?? 'An unknown error occurred',
            uri: response.request?.url);
      } on FormatException {
        throw HttpException('Server error: ${response.statusCode}',
            uri: response.request?.url);
      } catch (e) {
        throw HttpException(
            'Request failed: ${response.statusCode} - ${response.body}',
            uri: response.request?.url);
      }
    }
  }

  /// Performs a POST request to the API.
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await _request('POST', endpoint, body: json.encode(body));
    return _handleResponse(response);
  }

  /// Performs a PUT request to the API.
  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final response = await _request('PUT', endpoint, body: json.encode(body));
    return _handleResponse(response);
  }

  /// Performs a DELETE request to the API.
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _request('DELETE', endpoint);
    return _handleResponse(response);
  }

  /// Uploads a file to the API.
  Future<Map<String, dynamic>> uploadFile(
      String endpoint, String filePath) async {
    final response = await _request('POST', endpoint,
        isUpload: true, filePath: filePath);
    return _handleResponse(response);
  }
}
