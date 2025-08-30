import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

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
      debugPrint('Auth error (signUp): ${e.code}');
      throw Exception(_friendly(e));
    }
  }

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
      debugPrint('Auth error (signIn): ${e.code}');
      throw Exception(_friendly(e));
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  /// NEW: send verification email to the currently signed-in user (if unverified)
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'That email is already registered.';
      case 'invalid-email': return 'The email address is not valid.';
      case 'operation-not-allowed': return 'Email/password sign-in is disabled.';
      case 'weak-password': return 'Password is too weak (minimum 6 characters).';
      case 'user-disabled': return 'This account has been disabled.';
      case 'user-not-found': return 'No account found for that email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'network-request-failed': return 'Network error. Please check your connection.';
      default: return e.message ?? 'Authentication error. Please try again.';
    }
  }
}
