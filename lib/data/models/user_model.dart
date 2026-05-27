import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:habitshare/domain/entities/user_entity.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  factory UserModel.fromFirebaseUser(firebase.User user) => UserModel(
    id: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );

  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
  );
}
