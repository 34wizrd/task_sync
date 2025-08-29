// lib/core/services/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_failure.dart';
import '../types/result.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<Result<UserCredential, AuthFailure>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return Result.ok(cred);
    } on FirebaseAuthException catch (e) {
      return Result.err(_map(e));
    } catch (_) {
      return Result.err(AuthFailure.unknown());
    }
  }

  Future<Result<UserCredential, AuthFailure>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return Result.ok(cred);
    } on FirebaseAuthException catch (e) {
      return Result.err(_map(e));
    } catch (_) {
      return Result.err(AuthFailure.unknown());
    }
  }

  Future<void> signOut() => _auth.signOut();

  AuthFailure _map(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':         return AuthFailure.invalidEmail();
      case 'user-disabled':         return AuthFailure.userDisabled();
      case 'user-not-found':        return AuthFailure.userNotFound();
      case 'wrong-password':        return AuthFailure.wrongPassword();
      case 'email-already-in-use':  return AuthFailure.emailAlreadyInUse();
      case 'weak-password':         return AuthFailure.weakPassword();
      case 'operation-not-allowed': return AuthFailure.operationNotAllowed();
      case 'network-request-failed':return AuthFailure.network();
      default:                      return AuthFailure.unknown(e.message);
    }
  }
}
