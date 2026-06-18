import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:habitshare/core/errors/exceptions.dart';
import 'package:habitshare/data/models/user_model.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn;

  static const Duration _googleSignInTimeout = Duration(seconds: 60);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

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
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null) {
        throw const AuthException('Registration failed');
      }
      return UserModel(
        id: refreshed.uid,
        email: refreshed.email ?? email,
        displayName: refreshed.displayName ?? displayName,
        photoUrl: refreshed.photoURL,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration failed', code: e.code);
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      // Clear any stale Google session so the account picker always appears.
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn().timeout(
        _googleSignInTimeout,
        onTimeout: () {
          throw const AuthException(
            'Google Sign-In timed out. Check your connection, then try again.',
            code: 'timeout',
          );
        },
      );

      if (googleUser == null) {
        throw const AuthException(
          'Google Sign-In was cancelled',
          code: 'cancelled',
        );
      }

      final googleAuth = await googleUser.authentication.timeout(
        _googleSignInTimeout,
        onTimeout: () {
          throw const AuthException(
            'Google Sign-In timed out while fetching credentials.',
            code: 'timeout',
          );
        },
      );

      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Google Sign-In did not return an ID token. Re-download '
          'google-services.json after adding SHA-1 and SHA-256 in Firebase, '
          'then rebuild the app.',
          code: 'missing-id-token',
        );
      }

      final userCredential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: googleAuth.accessToken,
        ),
      );
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Google sign in failed');
      }
      return UserModel.fromFirebaseUser(user);
    } on AuthException {
      rethrow;
    } on PlatformException catch (e) {
      throw _mapGooglePlatformException(e);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Google sign in failed', code: e.code);
    } catch (e) {
      final message = e.toString();
      if (message.contains('DEVELOPER_ERROR') ||
          message.contains('ApiException: 10')) {
        throw const AuthException(
          'Google Sign-In configuration error. Add debug and release SHA-1 '
          'and SHA-256 in Firebase Console, re-download google-services.json, '
          'uninstall the app, and rebuild.',
          code: 'developer-error',
        );
      }
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  AuthException _mapGooglePlatformException(PlatformException e) {
    final message = e.message ?? e.toString();
    final code = e.code;

    if (code == 'sign_in_canceled' || message.contains('canceled')) {
      return const AuthException(
        'Google Sign-In was cancelled',
        code: 'cancelled',
      );
    }

    if (message.contains('DEVELOPER_ERROR') ||
        message.contains('ApiException: 10') ||
        code == 'sign_in_failed') {
      return const AuthException(
        'Google Sign-In configuration error. Add debug and release SHA-1 '
        'and SHA-256 in Firebase Console, re-download google-services.json, '
        'uninstall the app, and rebuild.',
        code: 'developer-error',
      );
    }

    return AuthException(
      'Google Sign-In failed: ${message.isEmpty ? code : message}',
      code: code,
    );
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
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }
}
