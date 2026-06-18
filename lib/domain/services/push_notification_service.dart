import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:habitshare/config/constants/app_constants.dart';
import 'package:habitshare/core/errors/exceptions.dart';

class PushNotificationService {
  PushNotificationService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  // Callback to get user notification settings
  Future<Map<String, bool>> Function(String userId)? getNotificationSettings;

  /// Send a push notification to a specific user via their FCM topic.
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('=== PUSH NOTIFICATION START ===');
      print('User ID: $userId');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');

      if (getNotificationSettings == null) {
        print('ERROR: getNotificationSettings callback not set');
        print('=== PUSH NOTIFICATION FAILED (NO SETTINGS CALLBACK) ===');
        return;
      }
      final settings = await getNotificationSettings!(userId);
      print('User notification settings: $settings');

      final notificationType = _getNotificationTypeFromData(data);
      print('Notification type: $notificationType');
      if (notificationType != null && !(settings[notificationType] ?? true)) {
        print('User has disabled $notificationType notifications');
        print('=== PUSH NOTIFICATION SKIPPED (DISABLED) ===');
        return;
      }

      final topic = AppConstants.fcmUserTopic(userId);
      print('Sending to FCM topic: $topic');
      await _sendFCMMessageToTopic(
        topic: topic,
        title: title,
        body: body,
        data: data,
      );
      print('=== PUSH NOTIFICATION SUCCESS ===');
    } catch (e) {
      print('=== PUSH NOTIFICATION ERROR ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Send a push notification to multiple users
  Future<void> sendPushNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      for (final userId in userIds) {
        await sendPushNotification(
          userId: userId,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      print('Failed to send push notifications to users: $e');
    }
  }

  Future<void> _sendFCMMessageToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
      if (projectId == null || projectId.isEmpty) {
        print('ERROR: FIREBASE_PROJECT_ID not configured in .env file');
        throw ServerException(
          'Firebase project ID not configured',
          code: 'config-missing',
        );
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        print('ERROR: Failed to get OAuth2 access token');
        throw ServerException(
          'Failed to get OAuth2 access token',
          code: 'auth-error',
        );
      }

      final stringData = (data ?? {}).map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );

      print('Sending FCM message to Firebase using HTTP v1 API...');
      final response = await _dio.post<Map<String, dynamic>>(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        data: {
          'message': {
            'topic': topic,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': stringData,
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'default',
                'channel_id': 'habitshare_notifications',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                },
              },
            },
          },
        },
      );

      print('FCM response status: ${response.statusCode}');
      print('FCM response data: ${response.data}');

      if (response.statusCode != 200) {
        print('ERROR: FCM request failed with status ${response.statusCode}');
        throw ServerException(
          'FCM request failed with status ${response.statusCode}',
          code: 'fcm-error',
        );
      }
    } on DioException catch (e) {
      print('ERROR: Dio exception while sending FCM message: ${e.message}');
      print('Response: ${e.response?.data}');
      throw ServerException(
        e.message ?? 'Failed to send FCM message',
        code: 'dio-error',
      );
    }
  }

  Future<String?> _getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final serviceAccountPath = dotenv.env['FCM_SERVICE_ACCOUNT_JSON_PATH'];
      if (serviceAccountPath == null || serviceAccountPath.isEmpty) {
        print(
          'ERROR: FCM_SERVICE_ACCOUNT_JSON_PATH not configured in .env file',
        );
        return null;
      }

      final assetPath = serviceAccountPath.replaceFirst('./', '');

      String jsonContent;
      try {
        jsonContent = await rootBundle.loadString(assetPath);
      } catch (e) {
        print(
          'ERROR: Service account JSON file not found in assets at $assetPath',
        );
        return null;
      }

      final serviceAccount = json.decode(jsonContent) as Map<String, dynamic>;
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;

      _cachedAccessToken = accessToken;
      _tokenExpiry = client.credentials.accessToken.expiry;

      client.close();
      return accessToken;
    } catch (e) {
      print('ERROR: Failed to get OAuth2 token: $e');
      return null;
    }
  }

  String? _getNotificationTypeFromData(Map<String, dynamic>? data) {
    if (data == null) return null;

    final type = data['type'] as String?;
    switch (type) {
      case 'like':
        return 'likes';
      case 'comment':
        return 'comments';
      case 'followRequest':
      case 'followAccepted':
        return 'follows';
      case 'newPost':
        return 'new_posts';
      default:
        return null;
    }
  }
}
