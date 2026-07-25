import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final int buildNumber;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.buildNumber,
  });
}

class UpdateService {
  static const String _repo = 'Lodoapoza/SimuRH';
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$_repo/releases/tags/nightly');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? 'nightly';
      final body = data['body'] as String? ?? '';
      final assets = data['assets'] as List? ?? [];

      String? downloadUrl;
      for (final asset in assets) {
        if ((asset['name'] as String? ?? '').endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (downloadUrl == null) return null;

      // Extract build number from release notes or tag
      final buildMatch = RegExp(r'Build #(\d+)').firstMatch(body);
      final buildNumber = buildMatch != null ? int.parse(buildMatch.group(1)!) : 0;

      return UpdateInfo(
        latestVersion: tagName,
        downloadUrl: downloadUrl,
        releaseNotes: body,
        buildNumber: buildNumber,
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> getCurrentBuildNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.buildNumber;
      return int.tryParse(version) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
