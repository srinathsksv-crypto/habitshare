import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/repositories/import_export_repository.dart';

class ExportUseCase {
  const ExportUseCase(this._repository);

  final IImportExportRepository _repository;

  Future<Either<Failure, String>> call(List<HabitEntity> habits) =>
      _repository.exportHabitsToCsv(habits);
}
