import '../../../core/base/base_notifier.dart';
import '../../../core/services/auth_service.dart';

/// Login flow notifier using BaseNotifier for loading/error.
class LoginNotifier extends BaseNotifier {
  LoginNotifier(this._auth);
  final AuthService _auth;

  bool _obscure = true;
  bool _remember = false;

  bool get obscure => _obscure;
  bool get remember => _remember;

  void toggleObscure() {
    _obscure = !_obscure;
    notifyListeners();
  }

  void toggleRemember(bool v) {
    _remember = v;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await guard(() async {
      final res = await _auth.signIn(email: email, password: password);
      if (res == null) {
        throw Exception('Authentication failed. Please check your email and password.');
      }
    });
  }
}
