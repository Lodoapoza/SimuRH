import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LicenseInfo {
  final String etablissement;
  final int expiryYear;
  final String key;

  LicenseInfo({
    required this.etablissement,
    required this.expiryYear,
    required this.key,
  });

  bool get isExpired => DateTime.now().year > expiryYear;
}

class LicenseService {
  static final LicenseService _instance = LicenseService._internal();
  factory LicenseService() => _instance;
  LicenseService._internal();

  static const String _secret = 'SIMURH_LICENSE_2026_V1';
  static const String _prefKey = 'simurh_license';
  static const String _prefEtab = 'simurh_etablissement';
  static const String _prefExpiry = 'simurh_expiry_year';
  static const String _isActivatedKey = 'simurh_activated';

  /// Calcule la clé HMAC-SHA256 pour un établissement et une année donnés.
  /// Formule : HMAC(etablissement_lower, secret) → first 8 hex chars
  static String _computePrefix(String etablissement) {
    final key = utf8.encode(_secret);
    final data = utf8.encode(etablissement.toLowerCase());
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return digest.toString().substring(0, 8).toUpperCase();
  }

  /// Valide une clé complète (KKKK-KKKK-YYYY) pour un établissement.
  static Future<bool> validate(String etablissement, String rawKey) async {
    final clean = rawKey.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (clean.length != 12) return false;

    final prefix = clean.substring(0, 8);
    final yearStr = clean.substring(8, 12);

    if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(clean)) return false;

    final expectedPrefix = _computePrefix(etablissement);
    if (prefix != expectedPrefix) return false;

    final year = int.tryParse(yearStr, radix: 16);
    if (year == null) return false;

    try {
      final serverUrl = 'https://simurh.glocal-innov.com/api/license/validate';
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'establishment': etablissement, 'key': clean}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] == true;
      }
    } catch (_) {}

    return true;
  }

  /// Active la licence pour un établissement avec une clé.
  static Future<bool> activate(String etablissement, String rawKey) async {
    final clean = rawKey.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (!await validate(etablissement, clean)) return false;

    final yearStr = clean.substring(8, 12);
    final year = int.parse(yearStr, radix: 16);
    final key = clean.substring(0, 4) + '-' + clean.substring(4, 8) + '-' + yearStr;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isActivatedKey, true);
    await prefs.setString(_prefKey, key);
    await prefs.setString(_prefEtab, etablissement);
    await prefs.setInt(_prefExpiry, year);

    return true;
  }

  /// Vérifie si l'app est activée et la licence valide.
  static Future<bool> isValid() async {
    final prefs = await SharedPreferences.getInstance();
    final activated = prefs.getBool(_isActivatedKey) ?? false;
    if (!activated) return false;

    final year = prefs.getInt(_prefExpiry) ?? 0;
    final etablissement = prefs.getString(_prefEtab) ?? '';
    if (year == 0 || etablissement.isEmpty) return false;

    // Vérifier expiration
    if (DateTime.now().year > year) return false;

    // Re-valider la clé
    final savedKey = prefs.getString(_prefKey) ?? '';
    return await validate(etablissement, savedKey);
  }

  /// Retourne les infos de la licence active.
  static Future<LicenseInfo?> getLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final activated = prefs.getBool(_isActivatedKey) ?? false;
    if (!activated) return null;

    final etablissement = prefs.getString(_prefEtab) ?? '';
    final year = prefs.getInt(_prefExpiry) ?? 0;
    final key = prefs.getString(_prefKey) ?? '';

    if (etablissement.isEmpty || year == 0 || key.isEmpty) return null;

    return LicenseInfo(etablissement: etablissement, expiryYear: year, key: key);
  }

  /// Réinitialise la licence (désactivation).
  static Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isActivatedKey);
    await prefs.remove(_prefKey);
    await prefs.remove(_prefEtab);
    await prefs.remove(_prefExpiry);
  }

  // ─── Méthodes de compatibilité (ancienne API) ────────────────────

  /// Retourne le statut de la licence (ancienne API).
  Future<Map<String, dynamic>> checkStatus() async {
    final license = await getLicense();
    final activated = license != null;
    final expired = activated ? license.isExpired : false;
    return {
      'status': activated && !expired ? 'active' : 'inactive',
      'type': 'license',
      'student_count': 999,
      'simulation_count': 999,
      'expiry_year': license?.expiryYear ?? 0,
      'establishment': license?.etablissement ?? '',
    };
  }

  /// Ancienne API : retourne true si en mode trial.
  /// Dans le nouveau modèle offline, on n'utilise que les clés.
  static bool isTrialMode() => false;

  /// Ancienne API : vérifie si on peut créer une simulation.
  /// Retourne null si pas de limite, ou un int (nombre restant).
  static Future<int?> canCreateSimulation() async {
    final valid = await isValid();
    return valid ? null : 0;
  }

  /// Ancienne API : achat de licence (CinetPay).
  /// Dans le nouveau modèle, utiliser ActivationScreen avec une clé.
  static Future<Map<String, dynamic>> purchaseLicense({
    required int establishmentId,
    required String phone,
  }) async {
    return {
      'success': false,
      'error': 'Le paiement en ligne n\'est plus disponible. '
          'Utilisez la clé d\'activation fournie par votre administrateur.',
    };
  }

  /// Ancienne API : vérification du paiement.
  static Future<Map<String, dynamic>> checkPaymentStatus(
      String transactionId) async {
    return {
      'payment_status': 'unknown',
      'license_status': 'inactive',
    };
  }
}
