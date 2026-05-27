import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/repositories/habit_repository.dart';

class GetHabitsUseCase {
  const GetHabitsUseCase(this._repository);

  final IHabitRepository _repository;

  Future<Either<Failure, List<HabitEntity>>> call(String userId) =>
      _repository.getHabits(userId);
}
