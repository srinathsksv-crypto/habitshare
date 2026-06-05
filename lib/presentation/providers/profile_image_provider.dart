import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/utils/profile_image_utils.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';

/// Resolves a profile photo reference (storage path or URL) to a displayable URL.
/// Cached per [photoReference] to avoid repeated Storage lookups on rebuilds.
final profileImageUrlProvider =
    FutureProvider.family<String?, String>((ref, photoReference) async {
  final trimmed = photoReference.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final storagePath = ProfileImageUtils.resolveStorageReference(trimmed);
  if (storagePath == null) {
    return trimmed.startsWith('http') ? trimmed : null;
  }

  final result =
      await ref.read(socialRepositoryProvider).getProfileImageUrl(trimmed);
  return result.fold(
    (_) => trimmed.startsWith('http') ? trimmed : null,
    (url) => url,
  );
});
