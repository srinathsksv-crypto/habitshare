import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/di/service_locator.dart';
import 'package:habitshare/domain/repositories/fcm_token_repository.dart';

final fcmTokenRepositoryProvider = Provider<IFCMTokenRepository>((ref) {
  return sl<IFCMTokenRepository>();
});
