
import '../base/base_notifier.dart';

/// Holds sync state & wires your real SyncService via setHandler().
class SyncNotifier extends BaseNotifier {
  bool _isSyncing = false;
  int _pending = 0;
  DateTime? _lastSyncedAt;

  bool get isSyncing => _isSyncing;
  int get pending => _pending;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> Function()? _handler;

  void setHandler(Future<void> Function() handler) => _handler = handler;

  void setPending(int count) { _pending = count; notifyListeners(); }

  Future<void> sync() async {
    if (_handler == null || _isSyncing) return;
    _setSyncing(true);
    await guard(() async {
      await _handler!.call();
      _lastSyncedAt = DateTime.now();
    });
    _setSyncing(false);
  }

  void _setSyncing(bool v) { if (_isSyncing == v) return; _isSyncing = v; notifyListeners(); }
}
