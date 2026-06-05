import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/utils/profile_image_utils.dart';
import 'package:habitshare/presentation/providers/profile_image_provider.dart';

/// Avatar that supports Firebase Storage paths, download URLs, and initials.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.fallbackText,
    this.radius = 24,
  });

  final String? photoUrl;
  final String fallbackText;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = photoUrl?.trim();
    if (reference == null || reference.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Text(fallbackText),
      );
    }

    if (reference.startsWith('http') &&
        ProfileImageUtils.storagePathFromDownloadUrl(reference) == null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(reference),
        onBackgroundImageError: (_, __) {},
        child: Text(fallbackText),
      );
    }

    final resolved = ref.watch(profileImageUrlProvider(reference));
    return resolved.when(
      data: (imageUrl) {
        if (imageUrl != null && imageUrl.startsWith('http')) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: CachedNetworkImageProvider(imageUrl),
            onBackgroundImageError: (_, __) {},
          );
        }
        return CircleAvatar(
          radius: radius,
          child: Text(fallbackText),
        );
      },
      loading: () => CircleAvatar(
        radius: radius,
        child: Text(fallbackText),
      ),
      error: (_, __) => CircleAvatar(
        radius: radius,
        child: Text(fallbackText),
      ),
    );
  }
}
