import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/repositories/fcm_token_repository.dart';
import 'package:habitshare/presentation/providers/fcm_provider.dart';

final fcmControllerProvider = Provider<FCMController>((ref) {
  return FCMController(ref.read(fcmTokenRepositoryProvider));
});

class FCMController {
  FCMController(this._fcmRepository);

  final IFCMTokenRepository _fcmRepository;

  /// Initialize FCM and register token for the current user
  Future<void> initializeFCM(String userId) async {
    try {
      print('Initializing FCM for user: $userId');

      // Request notification permissions
      await _fcmRepository.requestPermissions();

      // Get the current FCM token
      final tokenResult = await _fcmRepository.getFCMToken();
      tokenResult.fold(
        (failure) => print('Failed to get FCM token: ${failure.message}'),
        (token) async {
          print('Got FCM token: ${token.substring(0, 20)}...');
          // Save the token to Firestore
          await _fcmRepository.saveFCMToken(userId: userId, token: token);
          print('FCM token registered successfully for user: $userId');
        },
      );
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  /// Delete FCM token (e.g., on logout)
  Future<void> deleteFCMToken(String userId) async {
    try {
      final tokenResult = await _fcmRepository.getFCMToken();
      tokenResult.fold(
        (failure) => print('Failed to get FCM token: ${failure.message}'),
        (token) async {
          await _fcmRepository.deleteFCMToken(userId: userId, token: token);
          print('FCM token deleted successfully');
        },
      );
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }

  /// Subscribe to user-specific notifications
  Future<void> subscribeToUserNotifications(String userId) async {
    try {
      await _fcmRepository.subscribeToTopic('user_$userId');
      print('Subscribed to user notifications');
    } catch (e) {
      print('Error subscribing to user notifications: $e');
    }
  }

  /// Unsubscribe from user-specific notifications
  Future<void> unsubscribeFromUserNotifications(String userId) async {
    try {
      await _fcmRepository.unsubscribeFromTopic('user_$userId');
      print('Unsubscribed from user notifications');
    } catch (e) {
      print('Error unsubscribing from user notifications: $e');
    }
  }
}
