import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:habitshare/config/router/app_router.dart';
import 'package:habitshare/data/datasources/remote/fcm_datasource.dart';
import 'package:habitshare/firebase_options.dart';
import 'package:habitshare/presentation/screens/notifications_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
}

class FCMMessageHandler {
  FCMMessageHandler(this._fcmDataSource);

  final FCMDataSource _fcmDataSource;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM and set up message handlers
  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // iOS + cross-platform FCM permission prompt
    await _fcmDataSource.requestPermissions();

    // Android 13+ requires a runtime POST_NOTIFICATIONS grant on physical devices.
    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message (app opened from notification when terminated)
    final initialMessage = await _fcmDataSource.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _navigateBasedOnData(data);
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Create notification channel for Android O+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'habitshare_notifications',
      'HabitShare Notifications',
      description: 'Notifications from HabitShare',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    // Do not show local notification if the user is already on the notifications screen
    if (NotificationsScreen.isVisible) {
      return;
    }
    
    _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'habitshare_notifications',
      'HabitShare Notifications',
      channelDescription: 'Notifications from HabitShare',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle messages when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened from notification: ${message.notification?.title}');
    // Navigate to appropriate screen based on message data
    _navigateBasedOnMessage(message);
  }

  /// Navigate to appropriate screen based on message data
  void _navigateBasedOnMessage(RemoteMessage message) {
    print('Message opened from notification: ${message.notification?.title}');
    _navigateBasedOnData(message.data);
  }

  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final senderId = data['sender_id'] as String?;
    final postId = data['post_id'] as String?;

    print('Navigation data - type: $type, senderId: $senderId, postId: $postId');

    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      print('Navigation failed: context is null');
      return;
    }

    if (type == 'like' || type == 'comment' || type == 'newPost') {
      if (postId != null) {
        // For 'newPost', the sender is the post author/owner.
        // For 'like' or 'comment', the receiver is the post owner (current user).
        final receiverId = data['receiver_id'] as String?;
        final postOwnerId = type == 'newPost' ? senderId : receiverId;
        
        if (postOwnerId != null) {
          context.push('/home/post?postId=$postId&postOwnerId=$postOwnerId');
        }
      }
    } else if (type == 'followRequest' || type == 'followAccepted') {
      context.push('/home/profile');
    }
  }
}
