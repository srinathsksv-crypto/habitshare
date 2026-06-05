import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/app.dart';
import 'package:habitshare/core/di/service_locator.dart';
import 'package:habitshare/core/logger/app_logger.dart';
import 'package:habitshare/domain/services/fcm_message_handler.dart';
import 'package:habitshare/firebase_options.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await dotenv.load(fileName: '.env');
      await configureDependencies();

      // Initialize FCM message handler
      final fcmHandler = sl<FCMMessageHandler>();
      await fcmHandler.initialize();

      FlutterError.onError = (details) {
        AppLogger.error(
          details.exceptionAsString(),
          details.exception,
          details.stack,
        );
      };

      runApp(const ProviderScope(child: HabitShareApp()));
    },
    (error, stack) => AppLogger.error('Unhandled zone error', error, stack),
  );
}
