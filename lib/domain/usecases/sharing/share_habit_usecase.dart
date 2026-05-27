import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/shared_habit_entity.dart';
import 'package:habitshare/domain/repositories/sharing_repository.dart';

class ShareHabitUseCase {
  const ShareHabitUseCase(this._repository);

  final ISharingRepository _repository;

  Future<Either<Failure, SharedHabitEntity>> call({
    required String habitId,
    required String ownerId,
    required String sharedWithUserId,
    String? message,
  }) => _repository.shareHabit(
    habitId: habitId,
    ownerId: ownerId,
    sharedWithUserId: sharedWithUserId,
    message: message,
  );
}
