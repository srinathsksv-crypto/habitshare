import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';

enum SyncStatus { idle, syncing, offline, error }

abstract class ISyncRepository {
  Stream<SyncStatus> watchSyncStatus();

  Future<Either<Failure, void>> syncPendingChanges();

  Future<Either<Failure, int>> getPendingCount();
}
