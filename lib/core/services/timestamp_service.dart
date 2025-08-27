import 'package:shared_preferences/shared_preferences.dart';

class TimestampService {
  static const String _lastSyncKey = 'lastSyncTimestamp';

  /// Fetches the last sync timestamp from local storage.
  /// Returns 0 if no timestamp is found (for the very first sync).
  Future<int> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSyncKey) ?? 0;
  }

  /// Saves the current time as the new last sync timestamp.
  Future<void> updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastSyncKey, now);
    print("Updated last sync timestamp to: $now");
  }
}