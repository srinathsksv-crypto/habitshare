import 'dart:io';

void main() async {
  final keytoolPath = r'D:\AppDevelopment\AndroidStudio\jbr\bin\keytool.exe';

  // Check if keytool exists
  if (!File(keytoolPath).existsSync()) {
    print('keytool not found at $keytoolPath');
    return;
  }

  final args = [
    '-genkey',
    '-v',
    '-keystore',
    'android/app/release-keystore.jks',
    '-keyalg',
    'RSA',
    '-keysize',
    '2048',
    '-validity',
    '10000',
    '-alias',
    'upload',
    '-storepass',
    'habitshare123',
    '-keypass',
    'habitshare123',
    '-dname',
    'CN=HabitShare, OU=Development, O=HabitShare, L=City, S=State, C=US'
  ];

  print('Running keytool...');
  final result = await Process.run(keytoolPath, args);

  print('Exit code: ${result.exitCode}');
  print('stdout: ${result.stdout}');
  print('stderr: ${result.stderr}');

  if (result.exitCode == 0) {
    print('Generating SHA-1...');
    final listArgs = [
      '-list',
      '-v',
      '-keystore',
      'android/app/release-keystore.jks',
      '-alias',
      'upload',
      '-storepass',
      'habitshare123'
    ];
    final listResult = await Process.run(keytoolPath, listArgs);
    print('List exit code: ${listResult.exitCode}');
    print('List stdout: ${listResult.stdout}');
    print('List stderr: ${listResult.stderr}');
  }
}
