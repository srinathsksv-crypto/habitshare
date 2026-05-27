import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/repositories/habit_repository.dart';

class DeleteHabitUseCase {
  const DeleteHabitUseCase(this._repository);

  final IHabitRepository _repository;

  Future<Either<Failure, void>> call({
    required String userId,
    required String habitId,
  }) =>
      _repository.deleteHabit(userId: userId, habitId: habitId);
}
