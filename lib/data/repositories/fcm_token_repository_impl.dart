import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:habitshare/core/errors/error_mapper.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/data/datasources/remote/fcm_datasource.dart';
import 'package:habitshare/data/datasources/remote/firestore_datasource.dart';
import 'package:habitshare/domain/repositories/fcm_token_repository.dart';

class FCMTokenRepositoryImpl implements IFCMTokenRepository {
  FCMTokenRepositoryImpl(this._fcm, this._firestore);

  final FCMDataSource _fcm;
  final FirestoreDataSource _firestore;

  @override
  Future<Either<Failure, String>> getFCMToken() async {
    try {
      final token = await _fcm.getFCMToken();
      return Right(token);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> saveFCMToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore.saveFCMToken(userId: userId, token: token);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFCMToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore.deleteFCMToken(userId: userId, token: token);
      await _fcm.deleteFCMToken();
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> getNotificationSettings(
    String userId,
  ) async {
    try {
      final settings = await _firestore.getNotificationSettings(userId);
      return Right(settings);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateNotificationSettings({
    required String userId,
    required Map<String, bool> settings,
  }) async {
    try {
      await _firestore.updateNotificationSettings(
        userId: userId,
        settings: settings,
      );
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> requestPermissions() async {
    try {
      final settings = await _fcm.requestPermissions();
      return Right(settings);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}