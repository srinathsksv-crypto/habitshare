import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:habitshare/core/errors/failure.dart';

abstract class IFCMTokenRepository {
  /// Get the current FCM token
  Future<Either<Failure, String>> getFCMToken();

  /// Save FCM token to Firestore for the current user
  Future<Either<Failure, void>> saveFCMToken({
    required String userId,
    required String token,
  });

  /// Delete FCM token from Firestore (e.g., on logout)
  Future<Either<Failure, void>> deleteFCMToken({
    required String userId,
    required String token,
  });

  /// Subscribe to a topic (e.g., user-specific notifications)
  Future<Either<Failure, void>> subscribeToTopic(String topic);

  /// Unsubscribe from a topic
  Future<Either<Failure, void>> unsubscribeFromTopic(String topic);

  /// Request notification permissions
  Future<Either<Failure, NotificationSettings>> requestPermissions();

  /// Get notification settings for a user
  Future<Either<Failure, Map<String, bool>>> getNotificationSettings(
    String userId,
  );

  /// Update notification settings for a user
  Future<Either<Failure, void>> updateNotificationSettings({
    required String userId,
    required Map<String, bool> settings,
  });
}
