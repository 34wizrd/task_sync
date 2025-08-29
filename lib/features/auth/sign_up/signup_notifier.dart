import '../../../core/base/base_notifier.dart';
import '../../../core/services/auth_service.dart';

/// Sign-up flow notifier using BaseNotifier for loading/error.
class SignUpNotifier extends BaseNotifier {
  SignUpNotifier(this._auth);
  final AuthService _auth;

  bool _obscure = true;
  bool _acceptedTerms = false;

  bool get obscure => _obscure;
  bool get acceptedTerms => _acceptedTerms;

  void toggleObscure() {
    _obscure = !_obscure;
    notifyListeners();
  }

  void setAcceptedTerms(bool v) {
    _acceptedTerms = v;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await guard(() async {
      final res = await _auth.signUp(email: email, password: password);
      if (res == null) {
        throw Exception('Sign up failed. Try a different email and a stronger password.');
      }
    });
  }
}
