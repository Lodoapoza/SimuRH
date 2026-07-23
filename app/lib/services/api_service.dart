
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = 'https://cloud.glocal-innov.com/simurh/api/';
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

  /// Saves the token to SharedPreferences.
  static Future<void> _saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  /// Gets the authentication token.
  static String? getToken() => _token;

  /// Builds common headers for API requests.
  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
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
        throw HttpException('Request failed: ${response.statusCode} - ${response.body}',
            uri: response.request?.url);
      }
    }
  }

  /// Performs a GET request to the API.
  Future<Map<String, dynamic>> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  /// Performs a GET request expecting a list of data from the API.
  Future<List<Map<String, dynamic>>> getList(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http.get(uri, headers: _getHeaders());
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
        throw HttpException('Request failed: ${response.statusCode} - ${response.body}',
            uri: response.request?.url);
      }
    }
  }


  /// Performs a POST request to the API.
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response =
        await http.post(uri, headers: _getHeaders(), body: json.encode(body));
    return _handleResponse(response);
  }

  /// Performs a PUT request to the API.
  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response =
        await http.put(uri, headers: _getHeaders(), body: json.encode(body));
    return _handleResponse(response);
  }

  /// Performs a DELETE request to the API.
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await http.delete(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  /// Uploads a file to the API.
  Future<Map<String, dynamic>> uploadFile(String endpoint, String filePath) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_getHeaders())
      ..files.add(await http.MultipartFile.fromPath('file', filePath)); // 'file' is the expected field name

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }
}
