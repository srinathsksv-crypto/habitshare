import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bio,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? bio;

  String get name => displayName ?? email.split('@').first;

  UserEntity copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
  }) {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, bio];
}
