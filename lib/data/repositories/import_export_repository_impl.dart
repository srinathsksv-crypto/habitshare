import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/error_mapper.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/data/datasources/local/csv_datasource.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/repositories/import_export_repository.dart';

class ImportExportRepositoryImpl implements IImportExportRepository {
  ImportExportRepositoryImpl(this._csvDataSource);

  final CsvDataSource _csvDataSource;

  @override
  Future<Either<Failure, String>> exportHabitsToCsv(
    List<HabitEntity> habits,
  ) async {
    try {
      return Right(_csvDataSource.exportHabits(habits));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<HabitEntity>>> importHabitsFromCsv(
    String csvContent,
    String userId,
  ) async {
    try {
      return Right(_csvDataSource.importHabits(csvContent, userId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
