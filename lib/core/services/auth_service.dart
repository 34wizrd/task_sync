import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Stream to notify about changes in the user's sign-in state.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get the current signed-in user.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Sign up with email and password.
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
      // Handle errors (e.g., email already in use, weak password)
      print("Sign up failed: ${e.message}");
      return null;
    }
  }

  /// Sign in with email and password.
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
      // Handle errors (e.g., user not found, wrong password)
      print("Sign in failed: ${e.message}");
      return null;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}