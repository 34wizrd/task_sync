import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Stream to notify about changes in the user's sign-in state.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get the current signed-in user.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Sign up with email and password.
  /// NOTE: keeps the same return type, but now throws on failure with a friendly message.
  Future<UserCredential?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _log(e);
      throw Exception(_friendly(e));
    }
  }

  /// Sign in with email and password.
  /// NOTE: keeps the same return type, but now throws on failure with a friendly message.
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _log(e);
      throw Exception(_friendly(e));
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Map Firebase error codes to user-friendly messages.
  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication error. Please try again.';
    }
  }

  void _log(FirebaseAuthException e) {
    // Safe logging without PII
    debugPrint('Auth error: code=${e.code}');
  }
}
