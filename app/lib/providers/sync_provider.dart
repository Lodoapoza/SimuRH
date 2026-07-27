import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simurh/services/sync_service.dart';

class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSync;

  const SyncState({
    this.isOnline = false,
    this.isSyncing = false,
    this.lastSync,
  });
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService = SyncService();
  Timer? _periodicTimer;

  SyncNotifier() : super(const SyncState()) {
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final online = await _syncService.isOnline();
    state = SyncState(isOnline: online, lastSync: state.lastSync);
  }

  Future<void> syncAll() async {
    state = SyncState(isOnline: state.isOnline, isSyncing: true, lastSync: state.lastSync);
    await _syncService.syncAll();
    state = SyncState(isOnline: state.isOnline, isSyncing: false, lastSync: DateTime.now());
  }

  void startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) => syncAll());
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
