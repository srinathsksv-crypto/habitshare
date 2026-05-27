import 'package:habitshare/core/errors/exceptions.dart';
import 'package:habitshare/core/errors/failure.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is AppException) {
    return switch (error) {
      ServerException() => _mapServerFailure(error),
      CacheException() => CacheFailure(error.message),
      AuthException() => AuthFailure(error.message),
      NetworkException() => NetworkFailure(error.message),
      ValidationException() => ValidationFailure(error.message),
      SyncException() => SyncFailure(error.message),
    };
  }
  return UnknownFailure(error.toString());
}

Failure _mapServerFailure(ServerException error) {
  if (error.code == 'permission-denied') {
    return const ServerFailure(
      'Firestore blocked this action. Deploy firestore.rules to your Firebase project (see README).',
    );
  }
  return ServerFailure(error.message);
}
