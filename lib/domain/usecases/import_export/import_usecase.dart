import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/repositories/import_export_repository.dart';

class ImportUseCase {
  const ImportUseCase(this._repository);

  final IImportExportRepository _repository;

  Future<Either<Failure, List<HabitEntity>>> call({
    required String csvContent,
    required String userId,
  }) => _repository.importHabitsFromCsv(csvContent, userId);
}
