import 'package:equatable/equatable.dart';

enum FollowStatus { pending, accepted }

class FollowEntity extends Equatable {
  const FollowEntity({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.status = FollowStatus.accepted,
    this.followerName,
    this.followerEmail,
    this.followerPhotoUrl,
    this.followingName,
    this.followingEmail,
    this.followingPhotoUrl,
  });

  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;
  final FollowStatus status;
  final String? followerName;
  final String? followerEmail;
  final String? followerPhotoUrl;
  final String? followingName;
  final String? followingEmail;
  final String? followingPhotoUrl;

  String displayNameForTarget({required bool isFollowingList}) {
    if (isFollowingList) {
      return followingName ?? 'User';
    }
    return followerName ?? 'User';
  }

  String? photoUrlForTarget({required bool isFollowingList}) {
    return isFollowingList ? followingPhotoUrl : followerPhotoUrl;
  }

  String targetUserId({required bool isFollowingList}) {
    return isFollowingList ? followingId : followerId;
  }

  @override
  List<Object?> get props => [
    id,
    followerId,
    followingId,
    createdAt,
    status,
    followerName,
    followerEmail,
    followerPhotoUrl,
    followingName,
    followingEmail,
    followingPhotoUrl,
  ];
}
