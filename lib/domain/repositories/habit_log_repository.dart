import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/habit_log_entity.dart';

abstract class IHabitLogRepository {
  Stream<List<HabitLogEntity>> watchLogs(String habitId, String userId);

  Future<Either<Failure, HabitLogEntity>> logHabit(HabitLogEntity log);

  Future<Either<Failure, List<HabitLogEntity>>> getLogs(String habitId, String userId);

  Future<Either<Failure, int>> getStreak(String habitId, String userId);
}
