// lib/core/auth/auth_failure.dart
sealed class AuthFailure {
  const AuthFailure(this.message);
  final String message;

  // Common, UI-friendly buckets
  factory AuthFailure.invalidEmail()           => const _InvalidEmail();
  factory AuthFailure.userDisabled()           => const _UserDisabled();
  factory AuthFailure.userNotFound()           => const _UserNotFound();
  factory AuthFailure.wrongPassword()          => const _WrongPassword();
  factory AuthFailure.emailAlreadyInUse()      => const _EmailInUse();
  factory AuthFailure.weakPassword()           => const _WeakPassword();
  factory AuthFailure.operationNotAllowed()    => const _OpNotAllowed();
  factory AuthFailure.network()                => const _Network();
  factory AuthFailure.unknown([String? msg])   => _Unknown(msg);

  @override
  String toString() => message;
}

class _InvalidEmail extends AuthFailure { const _InvalidEmail(): super('The email address is not valid.'); }
class _UserDisabled extends AuthFailure { const _UserDisabled(): super('This account has been disabled.'); }
class _UserNotFound extends AuthFailure { const _UserNotFound(): super('No account found for that email.'); }
class _WrongPassword extends AuthFailure { const _WrongPassword(): super('Incorrect password. Please try again.'); }
class _EmailInUse extends AuthFailure { const _EmailInUse(): super('That email is already registered.'); }
class _WeakPassword extends AuthFailure { const _WeakPassword(): super('Password is too weak (min 6 chars).'); }
class _OpNotAllowed extends AuthFailure { const _OpNotAllowed(): super('Email/password sign-in is disabled.'); }
class _Network extends AuthFailure { const _Network(): super('Network error. Please check your connection.'); }
class _Unknown extends AuthFailure { _Unknown([String? m]): super(m ?? 'Authentication error. Please try again.'); }
