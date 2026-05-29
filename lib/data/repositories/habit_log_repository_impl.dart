import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/error_mapper.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/data/datasources/remote/firestore_datasource.dart';
import 'package:habitshare/data/models/habit_log_model.dart';
import 'package:habitshare/domain/entities/habit_log_entity.dart';
import 'package:habitshare/domain/repositories/habit_log_repository.dart';

class HabitLogRepositoryImpl implements IHabitLogRepository {
  HabitLogRepositoryImpl(this._remote);

  final FirestoreDataSource _remote;

  @override
  Stream<List<HabitLogEntity>> watchLogs(String habitId, String userId) {
    return _remote.watchHabitLogs(habitId, userId).map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<Either<Failure, HabitLogEntity>> logHabit(HabitLogEntity log) async {
    try {
      final model = HabitLogModelX.fromEntity(log);
      final created = await _remote.createHabitLog(model);
      return Right(created.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<HabitLogEntity>>> getLogs(String habitId, String userId) async {
    try {
      final models = await _remote.getHabitLogs(habitId, userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> getStreak(
    String habitId,
    String userId,
  ) async {
    try {
      final models = await _remote.getHabitLogs(habitId, userId);
      if (models.isEmpty) {
        return const Right(0);
      }
      final days = models
          .map((log) => AppDateUtils.startOfDay(log.loggedAt))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      var streak = 0;
      var expected = AppDateUtils.startOfDay(DateTime.now());
      for (final day in days) {
        if (AppDateUtils.isSameDay(day, expected)) {
          streak++;
          expected = expected.subtract(const Duration(days: 1));
        } else if (day.isBefore(expected)) {
          break;
        }
      }
      return Right(streak);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
