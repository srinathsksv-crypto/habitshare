import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/error_mapper.dart';
import 'package:habitshare/core/errors/exceptions.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/data/datasources/local/local_database.dart';
import 'package:habitshare/data/datasources/remote/firestore_datasource.dart';
import 'package:habitshare/data/models/habit_model.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/repositories/habit_repository.dart';

class HabitRepositoryImpl implements IHabitRepository {
  HabitRepositoryImpl(this._remote, this._local);

  final FirestoreDataSource _remote;
  final LocalDatabaseDataSource _local;

  @override
  Stream<List<HabitEntity>> watchHabits(String userId) {
    return _remote.watchHabits(userId).map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<Either<Failure, List<HabitEntity>>> getHabits(String userId) async {
    try {
      final models = await _remote.getHabits(userId);
      await _local.cacheHabits(
        models.map((m) => m.toJson()).toList(),
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      try {
        final cached = await _local.getCachedHabits(userId);
        if (cached.isNotEmpty) {
          final entities = cached
              .map((row) => HabitModel.fromJson(row).toEntity())
              .toList();
          return Right(entities);
        }
      } catch (_) {
        // Fall through to original error.
      }
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, HabitEntity>> createHabit(HabitEntity habit) async {
    try {
      final model = HabitModelX.fromEntity(habit);
      final created = await _remote.createHabit(model);
      return Right(created.toEntity());
    } catch (e) {
      if (!_shouldQueueOffline(e)) {
        return Left(mapExceptionToFailure(e));
      }
      await _local.enqueueSync(
        entityType: 'habit',
        entityId: habit.id,
        operation: 'create',
        payload: jsonEncode(HabitModelX.fromEntity(habit).toJson()),
      );
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, HabitEntity>> updateHabit(HabitEntity habit) async {
    try {
      final model = HabitModelX.fromEntity(habit);
      final updated = await _remote.updateHabit(model);
      return Right(updated.toEntity());
    } catch (e) {
      if (!_shouldQueueOffline(e)) {
        return Left(mapExceptionToFailure(e));
      }
      await _local.enqueueSync(
        entityType: 'habit',
        entityId: habit.id,
        operation: 'update',
        payload: jsonEncode(HabitModelX.fromEntity(habit).toJson()),
      );
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabit({
    required String userId,
    required String habitId,
  }) async {
    try {
      await _remote.deleteHabit(userId: userId, habitId: habitId);
      return const Right(null);
    } catch (e) {
      if (!_shouldQueueOffline(e)) {
        return Left(mapExceptionToFailure(e));
      }
      await _local.enqueueSync(
        entityType: 'habit',
        entityId: habitId,
        operation: 'delete',
        payload: jsonEncode({'id': habitId, 'user_id': userId}),
      );
      return Left(mapExceptionToFailure(e));
    }
  }

  bool _shouldQueueOffline(Object error) {
    if (error is ServerException && error.code == 'permission-denied') {
      return false;
    }
    return true;
  }
}
