import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:habitshare/core/errors/error_mapper.dart';
import 'package:habitshare/core/errors/failure.dart';
import 'package:habitshare/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:habitshare/data/datasources/remote/firestore_datasource.dart';
import 'package:habitshare/data/models/user_model.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl(this._authDataSource, this._firestoreDataSource);

  final FirebaseAuthDataSource _authDataSource;
  final FirestoreDataSource _firestoreDataSource;

  @override
  Stream<UserEntity?> watchAuthState() {
    return _authDataSource.watchAuthState().asyncMap((user) async {
      if (user == null) {
        return null;
      }
      return _mergeWithFirestoreProfile(user);
    });
  }

  Future<UserEntity?> _mergeWithFirestoreProfile(UserModel user) async {
    try {
      final profile = await _firestoreDataSource.getUserProfile(user.id);
      if (profile == null) {
        return user.toEntity();
      }
      return UserEntity(
        id: user.id,
        email: profile.email.isNotEmpty ? profile.email : user.email,
        displayName: profile.displayName ?? user.displayName,
        photoUrl: profile.photoUrl ?? user.photoUrl,
        bio: profile.bio,
      );
    } catch (_) {
      return user.toEntity();
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(await _mergeWithFirestoreProfile(user) ?? user.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await _authDataSource.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      return Right(await _mergeWithFirestoreProfile(user) ?? user.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await _authDataSource.signInWithGoogle();
      return Right(await _mergeWithFirestoreProfile(user) ?? user.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithApple() async {
    try {
      final user = await _authDataSource.signInWithApple();
      return Right(await _mergeWithFirestoreProfile(user) ?? user.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _authDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _authDataSource.getCurrentUser();
      if (user == null) {
        return const Right(null);
      }
      return Right(await _mergeWithFirestoreProfile(user));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
