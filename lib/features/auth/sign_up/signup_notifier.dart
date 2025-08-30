import '../../../core/base/base_notifier.dart';
import '../../../core/services/auth_service.dart';

class SignUpNotifier extends BaseNotifier {
  SignUpNotifier(this._auth);
  final AuthService _auth;

  bool _obscure = true;
  bool _acceptedTerms = false;
  String? _emailSentTo; // for UI messaging

  bool get obscure => _obscure;
  bool get acceptedTerms => _acceptedTerms;
  String? get emailSentTo => _emailSentTo;

  void toggleObscure() { _obscure = !_obscure; notifyListeners(); }
  void setAcceptedTerms(bool v) { _acceptedTerms = v; notifyListeners(); }

  /// Sign up -> send verification -> sign out so AuthGate stays on auth screens.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await guard(() async {
      _emailSentTo = null;
      await _auth.signUp(email: email, password: password); // auto-signed-in here
      await _auth.sendEmailVerification();                  // send link
      _emailSentTo = email;
      await _auth.signOut();                                // prevent routing to Home
    });
  }
}
