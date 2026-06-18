import 'package:google_sign_in/google_sign_in.dart';
import 'package:habitshare/config/constants/app_constants.dart';

/// Shared [GoogleSignIn] instance for Firebase Auth on Android/iOS.
///
/// Uses google_sign_in v6's legacy account-picker flow, which is more reliable
/// on physical Android devices than v7's Credential Manager integration (which
/// can hang without showing UI or returning a result).
GoogleSignIn createGoogleSignIn() {
  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: AppConstants.googleWebClientId,
  );
}
