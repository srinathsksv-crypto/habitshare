import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';

abstract class IImportExportRepository {
  Future<Either<Failure, String>> exportHabitsToCsv(List<HabitEntity> habits);

  Future<Either<Failure, List<HabitEntity>>> importHabitsFromCsv(
    String csvContent,
    String userId,
  );
}
