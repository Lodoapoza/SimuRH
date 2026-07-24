import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class LicenseService {
  static final LicenseService _instance = LicenseService._internal();
  factory LicenseService() => _instance;
  LicenseService._internal();

  static const String _licenseKey = 'license_status';
  static const String _trialModeKey = 'is_trial_mode';

  static String? _licenseStatus;
  static bool _isTrialMode = true;
  static int? _establishmentId;

  /// Initializes the license service from local storage.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _licenseStatus = prefs.getString(_licenseKey);
    _isTrialMode = prefs.getBool(_trialModeKey) ?? true;
    _establishmentId = prefs.getInt('establishment_id');
  }

  /// Checks license status from the server.
  Future<Map<String, dynamic>> checkStatus() async {
    try {
      final response = await ApiService().get('/establishments/status');
      _licenseStatus = response['license_status'];
      _isTrialMode = response['license_status'] == 'trial';
      await _saveLicenseStatus();
      return response;
    } catch (e) {
      return {
        'status': _licenseStatus,
        'is_trial_mode': _isTrialMode,
        'simulation_count': 0,
        'student_count': 0,
      };
    }
  }

  /// Saves license status to SharedPreferences.
  static Future<void> _saveLicenseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (_licenseStatus != null) {
      await prefs.setString(_licenseKey, _licenseStatus!);
    }
    await prefs.setBool(_trialModeKey, _isTrialMode);
  }

  /// Check if the establishment is in trial mode.
  static bool isTrialMode() => _isTrialMode;

  /// Check if the user can create a new simulation.
  /// Returns null if allowed, or an error message string if blocked.
  static Future<String?> canCreateSimulation() async {
    if (!_isTrialMode) return null; // active license: unlimited

    try {
      final api = ApiService();
      final data = await api.get('/establishments/status');
      final count = data['simulation_count'] as int? ?? 0;
      final maxSims = data['trial_limits']['max_simulations'] as int? ?? 1;
      if (count >= maxSims) {
        return 'Mode essai limité à $maxSims simulation. Achetez la licence complète.';
      }
      return null; // allowed
    } catch (_) {
      return null; // offline: allow (validation also happens server-side)
    }
  }

  /// Check if the user can add a new student.
  /// Returns null if allowed, or an error message string if blocked.
  static Future<String?> canAddStudent() async {
    if (!_isTrialMode) return null;

    try {
      final api = ApiService();
      final data = await api.get('/establishments/status');
      final count = data['student_count'] as int? ?? 0;
      final maxStudents = data['trial_limits']['max_students'] as int? ?? 1;
      if (count >= maxStudents) {
        return 'Mode essai limité à $maxStudents étudiant. Achetez la licence complète.';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Initiate a CinetPay payment.
  /// Returns { success, transaction_id, payment_url, amount, currency }.
  static Future<Map<String, dynamic>> purchaseLicense({
    required int establishmentId,
    required String phone,
  }) async {
    try {
      final api = ApiService();
      final response = await api.post('/payments/init', {
        'establishment_id': establishmentId,
        'phone': phone,
      });
      return response;
    } catch (e) {
      throw Exception('Échec de l\'initialisation du paiement : $e');
    }
  }

  /// Check payment status for a given transaction.
  static Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      final api = ApiService();
      return await api.get('/payments/status/$transactionId');
    } catch (e) {
      return {'payment_status': 'unknown', 'license_status': _licenseStatus};
    }
  }
}
