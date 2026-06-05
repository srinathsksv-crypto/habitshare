import 'package:get_it/get_it.dart';
import 'package:habitshare/data/datasources/local/csv_datasource.dart';
import 'package:habitshare/data/datasources/local/local_database.dart';
import 'package:habitshare/data/datasources/remote/fcm_datasource.dart';
import 'package:habitshare/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:habitshare/data/datasources/remote/firebase_storage_datasource.dart';
import 'package:habitshare/data/datasources/remote/firestore_datasource.dart';
import 'package:habitshare/data/repositories/auth_repository_impl.dart';
import 'package:habitshare/data/repositories/fcm_token_repository_impl.dart';
import 'package:habitshare/data/repositories/habit_log_repository_impl.dart';
import 'package:habitshare/data/repositories/habit_repository_impl.dart';
import 'package:habitshare/data/repositories/import_export_repository_impl.dart';
import 'package:habitshare/data/repositories/sharing_repository_impl.dart';
import 'package:habitshare/data/repositories/social_repository_impl.dart';
import 'package:habitshare/data/repositories/sync_repository_impl.dart';
import 'package:habitshare/domain/repositories/auth_repository.dart';
import 'package:habitshare/domain/repositories/fcm_token_repository.dart';
import 'package:habitshare/domain/repositories/habit_log_repository.dart';
import 'package:habitshare/domain/repositories/habit_repository.dart';
import 'package:habitshare/domain/repositories/import_export_repository.dart';
import 'package:habitshare/domain/repositories/sharing_repository.dart';
import 'package:habitshare/domain/repositories/social_repository.dart';
import 'package:habitshare/domain/repositories/sync_repository.dart';
import 'package:habitshare/domain/services/fcm_message_handler.dart';
import 'package:habitshare/domain/services/push_notification_service.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl
    ..registerLazySingleton(FirebaseAuthDataSource.new)
    ..registerLazySingleton(FirebaseStorageDataSource.new)
    ..registerLazySingleton(FCMDataSource.new)
    ..registerLazySingleton(LocalDatabaseDataSource.new)
    ..registerLazySingleton(CsvDataSource.new);

  // Register PushNotificationService
  sl.registerLazySingleton(PushNotificationService.new);

  // Register FirestoreDataSource with PushNotificationService
  sl.registerLazySingleton(
    () => FirestoreDataSource(pushService: sl<PushNotificationService>()),
  );

  // Set up callbacks for PushNotificationService
  final pushService = sl<PushNotificationService>();
  final firestore = sl<FirestoreDataSource>();
  pushService.getUserFCMTokens = firestore.getUserFCMTokens;
  pushService.getNotificationSettings = firestore.getNotificationSettings;

  sl
    ..registerLazySingleton<IAuthRepository>(
      () => AuthRepositoryImpl(
        sl<FirebaseAuthDataSource>(),
        sl<FirestoreDataSource>(),
      ),
    )
    ..registerLazySingleton<IHabitRepository>(
      () => HabitRepositoryImpl(
        sl<FirestoreDataSource>(),
        sl<LocalDatabaseDataSource>(),
      ),
    )
    ..registerLazySingleton<IHabitLogRepository>(
      () => HabitLogRepositoryImpl(sl<FirestoreDataSource>()),
    )
    ..registerLazySingleton<ISharingRepository>(
      () => SharingRepositoryImpl(sl<FirestoreDataSource>()),
    )
    ..registerLazySingleton<IImportExportRepository>(
      () => ImportExportRepositoryImpl(sl<CsvDataSource>()),
    )
    ..registerLazySingleton<ISyncRepository>(
      () => SyncRepositoryImpl(
        sl<LocalDatabaseDataSource>(),
        sl<FirestoreDataSource>(),
      ),
    )
    ..registerLazySingleton<ISocialRepository>(
      () => SocialRepositoryImpl(
        sl<FirestoreDataSource>(),
        sl<FirebaseStorageDataSource>(),
      ),
    )
    ..registerLazySingleton<IFCMTokenRepository>(
      () => FCMTokenRepositoryImpl(
        sl<FCMDataSource>(),
        sl<FirestoreDataSource>(),
      ),
    )
    ..registerLazySingleton(
      () => FCMMessageHandler(sl<FCMDataSource>()),
    );
}
