import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:habitshare/core/errors/exceptions.dart';
import 'package:habitshare/data/models/user_model.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final GoogleSignIn? _googleSignIn;

  Stream<UserModel?> watchAuthState() {
    return _auth.authStateChanges().map(
          (user) => user == null ? null : UserModel.fromFirebaseUser(user),
        );
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign in failed');
      }
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Authentication failed', code: e.code);
    }
  }

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Registration failed');
      }
      await user.updateDisplayName(displayName);
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration failed', code: e.code);
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final gSign = _googleSignIn ?? GoogleSignIn.instance;
      final googleUser = await gSign.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Google sign in failed');
      }
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Google sign in failed', code: e.code);
    } catch (e) {
      throw AuthException('Google Sign-In initialization failed: $e');
    }
  }

  Future<UserModel> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Apple sign in failed');
      }
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Apple sign in failed', code: e.code);
    }
  }

  Future<void> signOut() async {
    final futures = <Future<void>>[_auth.signOut()];
    try {
      final gSign = _googleSignIn ?? GoogleSignIn.instance;
      futures.add(gSign.signOut());
    } catch (_) {
      // Ignore Google Sign-In initialization/sign-out errors if client ID is not configured
    }
    await Future.wait(futures);
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }
}
