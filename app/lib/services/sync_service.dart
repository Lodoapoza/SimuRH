import 'dart:io';
import 'dart:async';
import 'api_service.dart';
import 'auth_service.dart';
import 'db_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Timer? _periodicTimer;
  static const _syncInterval = Duration(minutes: 5);

  /// Initializes the sync service.
  static Future<void> init() async {
    // Optionally start periodic sync if needed
  }

  /// Checks if the device is online by attempting to connect to the server.
  static Future<bool> isOnline() async {
    try {
      final uri = Uri.parse(ApiService.baseUrl);
      final host = uri.host;
      final port = uri.port;
      final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
      socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Synchronizes all data (simulations, groups, submissions) between local and server.
  Future<void> syncAll() async {
    if (!await isOnline()) {
      return;
    }

    await syncSimulations();
    await syncGroups();
    await syncPendingSubmissions();
  }

  /// Synchronizes pending submissions from local to server.
  Future<void> syncPendingSubmissions() async {
    if (!await isOnline()) {
      return;
    }

    final db = DbService();
    final pendingSubmissions = await db.getPendingSubmissions();

    for (var sub in pendingSubmissions) {
      try {
        // Send submission to server
        final response = await ApiService().post('/submissions', sub);
        // If successful, mark as synced
        await db.markSubmissionAsSynced(sub['id']);
      } catch (e) {
        // Keep as pending for next retry
        continue;
      }
    }
  }

  /// Synchronizes simulations from server to local cache.
  Future<void> syncSimulations() async {
    if (!await isOnline()) {
      return;
    }

    try {
      final simulations = await ApiService().getList('/simulations');
      final db = DbService();
      for (var sim in simulations) {
        await db.cacheSimulation(sim);
      }
    } catch (e) {
      // Handle error (e.g., log)
    }
  }

  /// Synchronizes groups from server to local cache.
  Future<void> syncGroups() async {
    if (!await isOnline()) {
      return;
    }

    try {
      final groups = await ApiService().getList('/groups');
      final db = DbService();
      for (var group in groups) {
        await db.cacheGroup(group);
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Starts periodic synchronization at the specified interval.
  void startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_syncInterval, (timer) async {
      await syncAll();
    });
  }

  /// Stops periodic synchronization.
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}