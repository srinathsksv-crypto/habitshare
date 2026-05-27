import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';

abstract class IHabitRepository {
  Stream<List<HabitEntity>> watchHabits(String userId);

  Future<Either<Failure, List<HabitEntity>>> getHabits(String userId);

  Future<Either<Failure, HabitEntity>> createHabit(HabitEntity habit);

  Future<Either<Failure, HabitEntity>> updateHabit(HabitEntity habit);

  Future<Either<Failure, void>> deleteHabit({
    required String userId,
    required String habitId,
  });
}
