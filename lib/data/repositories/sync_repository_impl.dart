import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/error_mapper.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/data/datasources/local/local_database.dart';
import 'package:habitshare/data/datasources/remote/firestore_datasource.dart';
import 'package:habitshare/data/models/habit_model.dart';
import 'package:habitshare/domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements ISyncRepository {
  SyncRepositoryImpl(this._local, this._remote);

  final LocalDatabaseDataSource _local;
  final FirestoreDataSource _remote;

  final _statusController = StreamController<SyncStatus>.broadcast();

  @override
  Stream<SyncStatus> watchSyncStatus() => _statusController.stream;

  @override
  Future<Either<Failure, void>> syncPendingChanges() async {
    _statusController.add(SyncStatus.syncing);
    try {
      final pending = await _local.getPendingSyncItems();
      for (final item in pending) {
        final operation = item['operation'] as String;
        final payload = item['payload'] as String;
        switch (operation) {
          case 'create':
            final createModel = HabitModel.fromJson(
              jsonDecode(payload) as Map<String, dynamic>,
            );
            await _remote.createHabit(createModel);
            break;
          case 'update':
            final updateModel = HabitModel.fromJson(
              jsonDecode(payload) as Map<String, dynamic>,
            );
            await _remote.updateHabit(updateModel);
            break;
          case 'delete':
            final data = jsonDecode(payload) as Map<String, dynamic>;
            await _remote.deleteHabit(
              userId: data['user_id'] as String,
              habitId: data['id'] as String,
            );
            break;
        }
        await _local.clearSyncItem(item['id'] as int);
      }
      _statusController.add(SyncStatus.idle);
      return const Right(null);
    } catch (e) {
      _statusController.add(SyncStatus.error);
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> getPendingCount() async {
    try {
      return Right(await _local.pendingCount());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
