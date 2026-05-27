import 'package:flutter/material.dart';
import 'package:habitshare/domain/entities/user_entity.dart';

class UserTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final name = user.name;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
      ),
      title: Text(name),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}
