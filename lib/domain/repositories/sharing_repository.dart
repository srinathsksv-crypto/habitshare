import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/shared_habit_entity.dart';

abstract class ISharingRepository {
  Future<Either<Failure, SharedHabitEntity>> shareHabit({
    required String habitId,
    required String ownerId,
    required String sharedWithUserId,
    String? message,
  });

  Future<Either<Failure, List<SharedHabitEntity>>> getSharedHabits(
    String userId,
  );

  Stream<List<SharedHabitEntity>> watchSharedHabits(String userId);
}
