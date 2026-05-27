import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/domain/repositories/sync_repository.dart';

class SyncUseCase {
  const SyncUseCase(this._repository);

  final ISyncRepository _repository;

  Future<Either<Failure, void>> call() => _repository.syncPendingChanges();
}
