import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class LicenseService {
  static final LicenseService _instance = LicenseService._internal();
  factory LicenseService() => _instance;
  LicenseService._internal();

  static const String _licenseKey = 'license_status';
  static const String _trialModeKey = 'is_trial_mode';

  /// Initializes the license service by loading the license status from SharedPreferences.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _licenseStatus = prefs.getString(_licenseKey);
    _isTrialMode = prefs.getBool(_trialModeKey) ?? true;
  }

  static String? _licenseStatus;
  static bool _isTrialMode;

  /// Checks the license status.
  Future<Map<String, dynamic>> checkStatus() async {
    try {
      final response = await ApiService().get('/license/status');
      _licenseStatus = response['status'];
      _isTrialMode = response['is_trial_mode'];
      await _saveLicenseStatus();
      return response;
    } catch (e) {
      return {'status': _licenseStatus, 'is_trial_mode': _isTrialMode};
    }
  }

  /// Saves the license status to SharedPreferences.
  static Future<void> _saveLicenseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_licenseKey, _licenseStatus!);
    await prefs.setBool(_trialModeKey, _isTrialMode);
  }

  /// Checks if the establishment is in trial mode.
  static bool isTrialMode() {
    return _isTrialMode;
  }

  /// Checks if the establishment can create a new simulation in trial mode.
  static bool canCreateSimulation() {
    // TO DO: implement logic based on license status
    return true; // placeholder
  }

  /// Checks if the establishment can add a new student in trial mode.
  static bool canAddStudent() {
    // TO DO: implement logic based on license status
    return true; // placeholder
  }

  /// Purchases a license.
  static Future<Map<String, dynamic>> purchaseLicense(String paymentMethod) async {
    try {
      final response = await ApiService().post('/license/purchase', {
        'payment_method': paymentMethod,
      });
      _licenseStatus = response['status'];
      _isTrialMode = response['is_trial_mode'];
      await _saveLicenseStatus();
      return response;
    } catch (e) {
      return {'status': _licenseStatus, 'is_trial_mode': _isTrialMode};
    }
  }
}