import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service de mise à jour automatique.
/// Utilise l'API GitHub Releases (accessible partout)
/// pour détecter les nouvelles versions de l'APK.
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String _githubApi =
      'https://api.github.com/repos/Lodoapoza/SimuRH/releases/tags/nightly';
  static const String _prefKey = 'last_update_build';

  /// Vérifie si une mise à jour est disponible.
  /// Retourne l'URL de téléchargement si une nouvelle version existe, null sinon.
  Future<String?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final response = await http.get(
        Uri.parse(_githubApi),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Extraire le numéro de build depuis le tag ou les notes
      final tagName = data['tag_name'] as String? ?? '';
      final notes = data['body'] as String? ?? '';

      int remoteBuild = 0;
      // Chercher "Build #N" dans les notes de release
      final buildMatch = RegExp(r'Build #(\d+)').firstMatch(notes);
      if (buildMatch != null) {
        remoteBuild = int.tryParse(buildMatch.group(1)!) ?? 0;
      }

      // Vérifier qu'on n'a pas déjà notifié pour ce build
      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getInt(_prefKey) ?? 0;

      if (remoteBuild > currentBuild && remoteBuild > lastNotified) {
        // Récupérer l'URL de l'APK
        final assets = data['assets'] as List? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name == 'SimuRH.apk') {
            final url = asset['browser_download_url'] as String?;
            if (url != null) return url;
          }
        }
      }

      return null;
    } catch (_) {
      return null; // Échec silencieux — on ne bloque pas l'app
    }
  }

  /// Marque une version comme déjà notifiée.
  Future<void> markNotified() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, int.tryParse(info.buildNumber) ?? 0);
  }

  /// Ouvre l'URL de téléchargement dans le navigateur.
  Future<bool> openDownloadUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
