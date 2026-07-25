import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
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
  static bool validate(String etablissement, String rawKey) {
    final clean = rawKey.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (clean.length != 12) return false;

    final prefix = clean.substring(0, 8);
    final yearStr = clean.substring(8, 12);

    // Valider le format hexadécimal
    if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(clean)) return false;

    final expectedPrefix = _computePrefix(etablissement);
    if (prefix != expectedPrefix) return false;

    // Vérifier l'année d'expiration
    final year = int.tryParse(yearStr, radix: 16);
    if (year == null) return false;

    return true;
  }

  /// Active la licence pour un établissement avec une clé.
  static Future<bool> activate(String etablissement, String rawKey) async {
    final clean = rawKey.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (!validate(etablissement, clean)) return false;

    final yearStr = clean.substring(8, 12);
    final year = int.parse(yearStr, radix: 16);
    final key = clean.substring(0, 8) + '-' + clean.substring(4, 8) + '-' + yearStr;

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
    return validate(etablissement, savedKey);
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
}
