import 'package:flutter/foundation.dart';

/// Centralized loading + error handling for all notifiers.
/// Call `await guard(() async { ... });` around async work.
abstract class BaseNotifier extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  @protected
  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @protected
  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// Wraps an async op with loading+error. Returns result or null on error.
  @protected
  Future<T?> guard<T>(Future<T> Function() op) async {
    setError(null);
    setLoading(true);
    try {
      return await op();
    } catch (e, st) {
      onError(e, st);
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Override to send errors to Crashlytics/Sentry if you like.
  @protected
  void onError(Object error, StackTrace stackTrace) {}
}
