import 'dart:io';
import 'dart:async';
import 'api_service.dart';

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

  /// Synchronizes all data — désactivée, mode 100% local.
  Future<void> syncAll() async {
    // Sync désactivée — mode 100% local
    return;
  }

  /// Synchronizes pending submissions — désactivée, mode 100% local.
  Future<void> syncPendingSubmissions() async {
    // Sync désactivée — mode 100% local
    return;
  }

  /// Synchronizes simulations — désactivée, mode 100% local.
  Future<void> syncSimulations() async {
    // Sync désactivée — mode 100% local
    return;
  }

  /// Synchronizes groups — désactivée, mode 100% local.
  Future<void> syncGroups() async {
    // Sync désactivée — mode 100% local
    return;
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