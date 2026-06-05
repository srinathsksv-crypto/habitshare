import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/widgets/profile_avatar.dart';

class UserTile extends ConsumerWidget {
  const UserTile({
    super.key,
    required this.user,
    this.trailing,
    this.subtitle,
  });

  final UserEntity user;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.name;
    return ListTile(
      leading: ProfileAvatar(
        photoUrl: user.photoUrl,
        fallbackText: name.isNotEmpty ? name[0].toUpperCase() : '?',
      ),
      title: Text(name),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}

