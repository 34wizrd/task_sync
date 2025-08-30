import 'package:flutter/foundation.dart';

abstract class BaseNotifier extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  @protected
  void setLoading(bool v) { if (_isLoading == v) return; _isLoading = v; notifyListeners(); }

  @protected
  void setError(String? m) { _error = m; notifyListeners(); }

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

  @protected
  void onError(Object error, StackTrace stackTrace) {}
}
