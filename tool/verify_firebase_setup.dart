// ignore_for_file: avoid_print
//
// Verifies that all Firebase / Google Sign-In files required for Android
// builds are present and that signing certificate SHA-1 fingerprints are
// registered in google-services.json.
//
// Usage:
//   dart run tool/verify_firebase_setup.dart
//
import 'dart:convert';
import 'dart:io';

const _applicationId = 'com.example.habitshare';

void main(List<String> args) {
  final strict = args.contains('--strict');
  var failed = false;

  print('=== HabitShare Firebase / Android setup check ===\n');

  failed = _checkRequiredFiles() || failed;
  failed = _checkPubspecAssets() || failed;
  failed = _checkGoogleServicesPackage() || failed;
  failed = _checkShaFingerprints() || failed;
  failed = _checkKeyProperties() || failed;
  failed = _checkEnvFile() || failed;

  print('');
  if (failed) {
    print('FAILED: Fix the issues above before building for a physical device.');
    print('See README.md → "Android device builds (Google Sign-In & FCM)".');
    exit(strict ? 1 : 1);
  }

  print('OK: Firebase Android setup looks complete.');
  exit(0);
}

bool _checkRequiredFiles() {
  var failed = false;
  const required = <String, String>{
    'android/app/google-services.json':
        'Download from Firebase Console → Project settings → Your apps → Android.',
    'lib/firebase_options.dart':
        'Run: dart pub global activate flutterfire_cli && flutterfire configure',
    '.env': 'Copy from .env.example and fill in values.',
    'firebase-service-account.json':
        'Download from Firebase Console → Project settings → Service accounts → Generate new private key.',
    'android/key.properties':
        'Copy from android/key.properties.example (needed for release builds).',
  };

  print('Required files:');
  for (final entry in required.entries) {
    final exists = File(entry.key).existsSync();
    print('  ${exists ? "[OK]" : "[MISSING]"} ${entry.key}');
    if (!exists) {
      print('         → ${entry.value}');
      failed = true;
    }
  }
  print('');
  return failed;
}

bool _checkPubspecAssets() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  var failed = false;

  print('pubspec.yaml assets:');
  for (final asset in ['firebase-service-account.json', '.env']) {
    final listed = pubspec.contains('- $asset');
    print('  ${listed ? "[OK]" : "[MISSING]"} $asset listed under flutter.assets');
    if (!listed) failed = true;
  }
  print('');
  return failed;
}

bool _checkGoogleServicesPackage() {
  final file = File('android/app/google-services.json');
  if (!file.existsSync()) return false;

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final clients = (json['client'] as List<dynamic>?) ?? [];
  final packageNames = <String>{};

  for (final client in clients) {
    final info = (client as Map<String, dynamic>)['client_info']
        as Map<String, dynamic>?;
    final android = info?['android_client_info'] as Map<String, dynamic>?;
    final name = android?['package_name'] as String?;
    if (name != null) packageNames.add(name);
  }

  final ok = packageNames.contains(_applicationId);
  print('google-services.json package name:');
  print(
    '  ${ok ? "[OK]" : "[MISMATCH]"} expected $_applicationId, found ${packageNames.join(", ")}',
  );
  print('');
  return !ok;
}

bool _checkShaFingerprints() {
  final file = File('android/app/google-services.json');
  if (!file.existsSync()) return false;

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final registered = <String>{};

  for (final client in (json['client'] as List<dynamic>?) ?? []) {
    final oauthClients =
        ((client as Map<String, dynamic>)['oauth_client'] as List<dynamic>?) ??
            [];
    for (final oauth in oauthClients) {
      final androidInfo =
          (oauth as Map<String, dynamic>)['android_info'] as Map<String, dynamic>?;
      final hash = androidInfo?['certificate_hash'] as String?;
      if (hash != null) registered.add(hash.toLowerCase());
    }
  }

  print('SHA-1 fingerprints in google-services.json:');
  if (registered.isEmpty) {
    print('  [MISSING] No Android OAuth certificate hashes found.');
    print(
      '         Add SHA-1 in Firebase Console → Project settings → Your apps → Android.',
    );
    print('');
    return true;
  }
  for (final hash in registered) {
    print('  registered: $hash');
  }

  var failed = false;
  final keystores = <_KeystoreSpec>[
    _KeystoreSpec(
      label: 'debug',
      path: _debugKeystorePath(),
      alias: 'androiddebugkey',
      storePassword: 'android',
      keyPassword: 'android',
    ),
    _KeystoreSpec(
      label: 'release',
      path: 'android/app/release-keystore.jks',
      alias: 'upload',
      storePassword: 'habitshare123',
      keyPassword: 'habitshare123',
      optional: true,
    ),
  ];

  print('');
  print('Local keystore SHA-1 vs Firebase:');
  for (final spec in keystores) {
    final sha1 = _readSha1(spec);
    if (sha1 == null) {
      if (!spec.optional) {
        print('  [MISSING] ${spec.label} keystore at ${spec.path}');
        failed = true;
      } else {
        print('  [SKIP] ${spec.label} keystore not found (${spec.path})');
      }
      continue;
    }

    final normalized = sha1.replaceAll(':', '').toLowerCase();
    final ok = registered.contains(normalized);
    print(
      '  ${ok ? "[OK]" : "[NOT REGISTERED]"} ${spec.label}: $sha1',
    );
    if (!ok) {
      print(
        '         Add this SHA-1 in Firebase Console, then re-download google-services.json.',
      );
      failed = true;
    }
  }
  print('');
  return failed;
}

bool _checkKeyProperties() {
  final file = File('android/key.properties');
  if (!file.existsSync()) return true;

  final props = _parseProperties(file.readAsStringSync());
  var failed = false;

  print('android/key.properties:');
  for (final key in ['storeFile', 'keyAlias', 'storePassword', 'keyPassword']) {
    final value = props[key];
    final ok = value != null && value.isNotEmpty;
    print('  ${ok ? "[OK]" : "[MISSING]"} $key');
    if (!ok) failed = true;
  }

  final storeFile = props['storeFile'];
  if (storeFile != null && storeFile.isNotEmpty) {
    // storeFile in key.properties is resolved relative to android/app/ (Gradle app module).
    final candidates = [
      'android/app/$storeFile',
      storeFile,
      'android/$storeFile',
    ];
    final resolved = candidates.any((path) => File(path).existsSync());
    print('  ${resolved ? "[OK]" : "[MISSING]"} keystore file: $storeFile');
    if (!resolved) failed = true;
  }
  print('');
  return failed;
}

bool _checkEnvFile() {
  final file = File('.env');
  if (!file.existsSync()) return true;

  final lines = file.readAsLinesSync();
  final values = <String, String>{};
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx <= 0) continue;
    values[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
  }

  var failed = false;
  print('.env values:');
  for (final key in [
    'FIREBASE_PROJECT_ID',
    'FCM_SERVICE_ACCOUNT_JSON_PATH',
  ]) {
    final ok = values[key]?.isNotEmpty == true;
    print('  ${ok ? "[OK]" : "[MISSING]"} $key');
    if (!ok) failed = true;
  }

  final serviceAccountPath =
      values['FCM_SERVICE_ACCOUNT_JSON_PATH']?.replaceFirst('./', '') ??
          'firebase-service-account.json';
  final serviceAccountExists = File(serviceAccountPath).existsSync();
  print(
    '  ${serviceAccountExists ? "[OK]" : "[MISSING]"} service account file: $serviceAccountPath',
  );
  if (!serviceAccountExists) failed = true;
  print('');
  return failed;
}

String _debugKeystorePath() {
  final home = Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      '';
  return '$home${Platform.pathSeparator}.android${Platform.pathSeparator}debug.keystore';
}

String? _readSha1(_KeystoreSpec spec) {
  if (!File(spec.path).existsSync()) return null;

  final result = Process.runSync(
    'keytool',
    [
      '-list',
      '-v',
      '-keystore',
      spec.path,
      '-alias',
      spec.alias,
      '-storepass',
      spec.storePassword,
      '-keypass',
      spec.keyPassword,
    ],
  );

  if (result.exitCode != 0) return null;

  final output = '${result.stdout}';
  final match = RegExp(r'SHA1:\s*([0-9A-F:]+)', caseSensitive: false)
      .firstMatch(output);
  return match?.group(1)?.toUpperCase();
}

Map<String, String> _parseProperties(String content) {
  final props = <String, String>{};
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx <= 0) continue;
    props[trimmed.substring(0, idx).trim()] =
        trimmed.substring(idx + 1).trim();
  }
  return props;
}

class _KeystoreSpec {
  const _KeystoreSpec({
    required this.label,
    required this.path,
    required this.alias,
    required this.storePassword,
    required this.keyPassword,
    this.optional = false,
  });

  final String label;
  final String path;
  final String alias;
  final String storePassword;
  final String keyPassword;
  final bool optional;
}
