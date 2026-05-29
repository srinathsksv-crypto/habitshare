import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/habit_log_entity.dart';
import 'package:habitshare/domain/repositories/habit_log_repository.dart';

class HabitStats {
  const HabitStats({
    required this.logs,
    required this.streak,
    required this.completionRate,
  });

  final List<HabitLogEntity> logs;
  final int streak;
  final double completionRate;
}

class GetHabitStatsUseCase {
  const GetHabitStatsUseCase(this._repository);

  final IHabitLogRepository _repository;

  Future<Either<Failure, HabitStats>> call({
    required String habitId,
    required String userId,
    int lookbackDays = 30,
  }) async {
    final logsResult = await _repository.getLogs(habitId, userId);
    final streakResult = await _repository.getStreak(habitId, userId);

    return logsResult.fold(
      Left.new,
      (logs) => streakResult.fold(
        Left.new,
        (streak) {
          final recent = logs.where((log) {
            final cutoff = DateTime.now().subtract(
              Duration(days: lookbackDays),
            );
            return log.loggedAt.isAfter(cutoff);
          }).toList();
          final rate = lookbackDays == 0
              ? 0.0
              : (recent.length / lookbackDays).clamp(0.0, 1.0);
          return Right(
            HabitStats(
              logs: logs,
              streak: streak,
              completionRate: rate,
            ),
          );
        },
      ),
    );
  }
}
