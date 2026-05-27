import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/error_mapper.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/data/datasources/remote/firestore_datasource.dart';
import 'package:habitshare/data/models/shared_habit_model.dart';
import 'package:habitshare/domain/entities/shared_habit_entity.dart';
import 'package:habitshare/domain/repositories/sharing_repository.dart';
import 'package:uuid/uuid.dart';

class SharingRepositoryImpl implements ISharingRepository {
  SharingRepositoryImpl(this._remote);

  final FirestoreDataSource _remote;

  @override
  Future<Either<Failure, SharedHabitEntity>> shareHabit({
    required String habitId,
    required String ownerId,
    required String sharedWithUserId,
    String? message,
  }) async {
    try {
      const uuid = Uuid();
      final model = SharedHabitModel(
        id: uuid.v4(),
        habitId: habitId,
        ownerId: ownerId,
        sharedWithUserId: sharedWithUserId,
        sharedAt: DateTime.now(),
        message: message,
      );
      final created = await _remote.shareHabit(model);
      return Right(created.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<SharedHabitEntity>>> getSharedHabits(
    String userId,
  ) async {
    try {
      final models = await _remote.getSharedHabits(userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<List<SharedHabitEntity>> watchSharedHabits(String userId) {
    return _remote.watchSharedHabits(userId).map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }
}
