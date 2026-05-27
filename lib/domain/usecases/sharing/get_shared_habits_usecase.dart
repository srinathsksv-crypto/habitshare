import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/shared_habit_entity.dart';
import 'package:habitshare/domain/repositories/sharing_repository.dart';

class GetSharedHabitsUseCase {
  const GetSharedHabitsUseCase(this._repository);

  final ISharingRepository _repository;

  Future<Either<Failure, List<SharedHabitEntity>>> call(String userId) =>
      _repository.getSharedHabits(userId);
}
