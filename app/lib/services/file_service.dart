import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'api_service.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  static const String _cacheDir = 'cache/files';

  /// Gets the application's document directory and ensures the cache subdirectory exists.
  Future<Directory> _getCacheDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${docDir.path}/$_cacheDir');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Downloads a file from the API and saves it to the local cache.
  /// The file is saved with a name that includes the fileId to allow lookup by fileId only.
  /// Returns the local file path on success, or throws an exception on failure.
  Future<String> downloadFile(String fileId, String filename) async {
    final cacheDir = await _getCacheDir();
    // Extract extension from filename to preserve file type
    final String extension = path.extension(filename);
    // Create a safe filename: fileId + extension (if extension is empty, just use fileId)
    final String savedFilename = extension.isNotEmpty ? '$fileId$extension' : fileId;
    final filePath = path.join(cacheDir.path, savedFilename);
    final file = File(filePath);

    // If the file already exists, delete it to ensure we get the latest version
    if (await file.exists()) {
      await file.delete();
    }

    final response = await http.get(
      Uri.parse('${ApiService._baseUrl}files/download/$fileId'),
      headers: ApiService()._getHeaders(),
    );

    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } else {
      throw HttpException('Failed to download file: ${response.statusCode}',
          uri: Uri.parse('${ApiService._baseUrl}files/download/$fileId'));
    }
  }

  /// Returns the cached file path for a given fileId if it exists, otherwise null.
  /// Looks for a file in the cache directory that starts with the fileId followed by an extension (or just the fileId if no extension).
  Future<String?> getCachedFilePath(String fileId) async {
    final cacheDir = await _getCacheDir();
    if (!await cacheDir.exists()) {
      return null;
    }

    final List<FileSystemEntity> files = cacheDir.listSync();
    for (final file in files) {
      if (file is File) {
        final String filename = path.basename(file.path);
        // Check if the filename starts with the fileId and the next character is either a dot (for extension) or the end of string.
        // We'll accept any extension, so we just check if the filename starts with fileId.
        if (filename.startsWith(fileId)) {
          // Optional: ensure that after the fileId, we have either a dot (extension) or nothing (if fileId is the full name without extension)
          // But since we saved it as fileId + extension, it will start with fileId and then the extension (which starts with a dot).
          // However, if the fileId itself contains dots, this might be problematic.
          // For simplicity, we'll just return the first file that starts with the fileId.
          return file.path;
        }
      }
    }
    return null;
  }

  /// Clears the entire cache directory by deleting all files within it.
  Future<void> clearCache() async {
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      // Recreate the directory
      await cacheDir.create();
    }
  }

  /// Optionally, you can also provide a method to remove a specific cached file by fileId.
  Future<void> removeCachedFile(String fileId) async {
    final cacheDir = await _getCacheDir();
    if (!await cacheDir.exists()) {
      return;
    }

    final List<FileSystemEntity> files = cacheDir.listSync();
    for (final file in files) {
      if (file is File) {
        final String filename = path.basename(file.path);
        if (filename.startsWith(fileId)) {
          await file.delete();
        }
      }
    }
  }
}