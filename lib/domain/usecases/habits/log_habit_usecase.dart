import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/habit_log_entity.dart';
import 'package:habitshare/domain/repositories/habit_log_repository.dart';

class LogHabitUseCase {
  const LogHabitUseCase(this._repository);

  final IHabitLogRepository _repository;

  Future<Either<Failure, HabitLogEntity>> call(HabitLogEntity log) =>
      _repository.logHabit(log);
}
