import 'dart:async';
import 'package:simurh/services/sync_client.dart';
import 'package:simurh/services/db_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SyncClient _client = SyncClient();
  final DbService _db = DbService();
  Timer? _periodicTimer;
  static const _syncInterval = Duration(minutes: 5);

  /// Static init — called from main.dart as SyncService.init()
  static Future<void> init() async {
    final svc = SyncService(); // gets the singleton
    await svc._client.loadConnection();
    if (svc._client.isConnected) {
      await svc.syncAll();
    }
    svc.startPeriodicSync();
  }

  Future<bool> isOnline() async {
    return _client.healthCheck();
  }

  Future<void> syncAll() async {
    await Future.wait([
      syncSimulations(),
      syncGroups(),
      syncPendingSubmissions(),
    ]);
  }

  Future<void> syncSimulations() async {
    try {
      final sims = await _client.fetchSimulations();
      if (sims.isEmpty) return;
      // Clear existing simulations and replace with server data
      await _db.delete('simulations');
      for (final sim in sims) {
        await _db.insert('simulations', sim);
      }
    } catch (_) {
      // Silently fail — will retry on next periodic sync
    }
  }

  Future<void> syncGroups() async {
    try {
      final groups = await _client.fetchGroups();
      if (groups.isEmpty) return;
      // Clear existing groups and members, then re-insert
      await _db.delete('groups_table');
      await _db.delete('group_members');
      for (final g in groups) {
        await _db.insert('groups_table', g);
        final members = g['members'] as List? ?? [];
        for (final m in members) {
          await _db.insert('group_members', {
            'group_id': g['id'],
            'student_name': m['student_name'],
            'server_member_id': m['id'],
          });
        }
      }
    } catch (_) {}
  }

  Future<void> syncPendingSubmissions() async {
    try {
      final pending = await _db.query('submissions',
          where: 'is_pending_sync = ?', whereArgs: [1]);
      for (final sub in pending) {
        final ok = await _client.postSubmission(sub);
        if (ok) {
          await _db.update('submissions', {'is_pending_sync': 0},
              where: 'id = ?', whereArgs: [sub['id']]);
        }
      }
    } catch (_) {}
  }

  void startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_syncInterval, (timer) async {
      await syncAll();
    });
  }

  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
