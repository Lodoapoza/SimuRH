import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class User {
  final int id;
  final String name;
  final String phone;
  final String role;
  final int establishmentId;
  final String establishmentName;
  final String? city;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.establishmentId,
    required this.establishmentName,
    this.city,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      establishmentId: json['establishment_id'] ?? json['establishmentId'] ?? 0,
      establishmentName: json['establishment_name'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'establishment_id': establishmentId,
      'establishment_name': establishmentName,
      'city': city,
    };
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  /// Logs in the user with phone and password.
  Future<User?> login(String phone, String password) async {
    try {
      final response = await ApiService().post('/auth/login', {
        'phone': phone,
        'password': password,
      });
      final token = response['token'];
      final userJson = response['user'];
      final user = User.fromJson(userJson);

      await _saveSession(token, user);
      return user;
    } catch (e) {
      // Re-throw or handle as needed
      throw Exception('Login failed: $e');
    }
  }

  /// Registers a new user.
  Future<User?> register(String name, String phone, String password, String role, String establishmentName, String? city) async {
    try {
      final response = await ApiService().post('/auth/register', {
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
        'establishment_name': establishmentName,
        'city': city,
      });
      final token = response['token'];
      final userJson = response['user'];
      final user = User.fromJson(userJson);

      await _saveSession(token, user);
      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Retrieves the current user from SharedPreferences.
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;

    final userJsonString = prefs.getString(_userKey);
    if (userJsonString == null) return null;

    try {
      final userJson = json.decode(userJsonString);
      return User.fromJson(userJson);
    } catch (e) {
      return null;
    }
  }

  /// Logs out the user by clearing the session.
  Future<void> logout() async {
    await _clearSession();
    ApiService.setToken(null);
  }

  /// Checks if the user is logged in.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey) && prefs.getString(_tokenKey) != null;
  }

  /// Gets the current token.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Saves the token and user to SharedPreferences.
  Future<void> _saveSession(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setInt('establishment_id', user.establishmentId);
    ApiService.setToken(token);
  }

  /// Clears the session from SharedPreferences.
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    ApiService.setToken(null);
  }
}