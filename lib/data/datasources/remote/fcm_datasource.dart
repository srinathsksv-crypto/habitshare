import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:habitshare/core/errors/exceptions.dart';
import 'package:firebase_core/firebase_core.dart';

class FCMDataSource {
  FCMDataSource({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// Get the current FCM token
  Future<String> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        throw ServerException(
          'Failed to get FCM token',
          code: 'token-null',
        );
      }
      return token;
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to get FCM token',
        code: e.code,
      );
    }
  }

  /// Delete the current FCM token
  Future<void> deleteFCMToken() async {
    try {
      await _messaging.deleteToken();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete FCM token',
        code: e.code,
      );
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to subscribe to topic',
        code: e.code,
      );
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to unsubscribe from topic',
        code: e.code,
      );
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      return settings;
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to request notification permissions',
        code: e.code,
      );
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await _messaging.getNotificationSettings();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to get notification settings',
        code: e.code,
      );
    }
  }

  /// Get the initial message when app is opened from notification
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await _messaging.getInitialMessage();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to get initial message',
        code: e.code,
      );
    }
  }

  /// Stream of messages when app is in foreground
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Stream of messages when app is opened from notification
  Stream<RemoteMessage?> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
