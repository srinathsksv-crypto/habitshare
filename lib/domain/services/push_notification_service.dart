import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:habitshare/core/errors/exceptions.dart';

class PushNotificationService {
  PushNotificationService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  // Callback to get user FCM tokens
  Future<List<String>> Function(String userId)? getUserFCMTokens;

  // Callback to get user notification settings
  Future<Map<String, bool>> Function(String userId)? getNotificationSettings;

  /// Send a push notification to a specific user
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

      // Get user's FCM tokens
      if (getUserFCMTokens == null) {
        print('ERROR: getUserFCMTokens callback not set');
        print('=== PUSH NOTIFICATION FAILED (NO CALLBACK) ===');
        return;
      }
      final tokens = await getUserFCMTokens!(userId);
      print('Retrieved ${tokens.length} FCM tokens for user: $userId');
      if (tokens.isEmpty) {
        print('ERROR: No FCM tokens found for user: $userId');
        print('=== PUSH NOTIFICATION FAILED (NO TOKENS) ===');
        return; // User has no registered FCM tokens
      }

      // Get user's notification settings
      if (getNotificationSettings == null) {
        print('ERROR: getNotificationSettings callback not set');
        print('=== PUSH NOTIFICATION FAILED (NO SETTINGS CALLBACK) ===');
        return;
      }
      final settings = await getNotificationSettings!(userId);
      print('User notification settings: $settings');

      // Check if notifications are enabled for this type
      final notificationType = _getNotificationTypeFromData(data);
      print('Notification type: $notificationType');
      if (notificationType != null && !(settings[notificationType] ?? true)) {
        print('User has disabled $notificationType notifications');
        print('=== PUSH NOTIFICATION SKIPPED (DISABLED) ===');
        return; // User has disabled this type of notification
      }

      // Send notification to all tokens
      for (final token in tokens) {
        print('Sending to token: ${token.substring(0, 20)}...');
        await _sendFCMMessage(
          token: token,
          title: title,
          body: body,
          data: data,
        );
        print('Successfully sent to token: ${token.substring(0, 20)}...');
      }
      print('=== PUSH NOTIFICATION SUCCESS ===');
    } catch (e) {
      // Log error but don't throw - push notifications should be non-blocking
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
      // Log error but don't throw
      print('Failed to send push notifications to users: $e');
    }
  }

  /// Send FCM message to a specific token using HTTP v1 API
  Future<void> _sendFCMMessage({
    required String token,
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

      // Get OAuth2 access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        print('ERROR: Failed to get OAuth2 access token');
        throw ServerException(
          'Failed to get OAuth2 access token',
          code: 'auth-error',
        );
      }

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
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data ?? {},
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'default',
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
      print('Response: ${e.response}');
      throw ServerException(
        e.message ?? 'Failed to send FCM message',
        code: 'dio-error',
      );
    }
  }

  /// Get OAuth2 access token from service account
  Future<String?> _getAccessToken() async {
    // Check if cached token is still valid
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final serviceAccountPath = dotenv.env['FCM_SERVICE_ACCOUNT_JSON_PATH'];
      if (serviceAccountPath == null || serviceAccountPath.isEmpty) {
        print(
            'ERROR: FCM_SERVICE_ACCOUNT_JSON_PATH not configured in .env file');
        print('Please add the path to your Firebase service account JSON file');
        return null;
      }

      // Read from assets using rootBundle instead of dart:io File
      // The .env usually has "./firebase-service-account.json", we strip the "./"
      final assetPath = serviceAccountPath.replaceFirst('./', '');
      
      String jsonContent;
      try {
        jsonContent = await rootBundle.loadString(assetPath);
      } catch (e) {
        print('ERROR: Service account JSON file not found in assets at $assetPath');
        return null;
      }

      final serviceAccount = json.decode(jsonContent) as Map<String, dynamic>;

      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;

      // Cache the token
      _cachedAccessToken = accessToken;
      _tokenExpiry = client.credentials.accessToken.expiry;

      client.close();
      return accessToken;
    } catch (e) {
      print('ERROR: Failed to get OAuth2 token: $e');
      return null;
    }
  }

  /// Get notification type from data
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
