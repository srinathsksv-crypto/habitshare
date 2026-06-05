/// Helpers for profile photos stored as Firebase Storage paths or download URLs.
class ProfileImageUtils {
  ProfileImageUtils._();

  static final _legacyTimestampSuffix = RegExp(r'_\d{10,}\.jpg$');

  /// Firebase Storage object path (e.g. `profiles/uid.jpg`), without query string.
  static String storageObjectPath(String reference) {
    final trimmed = reference.trim();
    if (trimmed.startsWith('http')) {
      return storagePathFromDownloadUrl(trimmed) ?? trimmed;
    }
    final uri = Uri.parse(trimmed);
    var path = uri.path;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return path;
  }

  /// Cache-busting query (e.g. `v=123`) when present on a storage reference.
  static String? cacheBustQuery(String reference) {
    if (reference.startsWith('http')) {
      return null;
    }
    final uri = Uri.parse(reference.trim());
    return uri.hasQuery ? uri.query : null;
  }

  /// Extracts `profiles/...` from a Firebase Storage download URL.
  static String? storagePathFromDownloadUrl(String url) {
    try {
      final path = Uri.parse(url).path;
      final oIndex = path.indexOf('/o/');
      if (oIndex == -1) {
        return null;
      }
      var objectPath = path.substring(oIndex + 3);
      if (objectPath.contains('%')) {
        objectPath = Uri.decodeComponent(objectPath);
      }
      if (objectPath.startsWith('/')) {
        objectPath = objectPath.substring(1);
      }
      return objectPath.isEmpty ? null : objectPath;
    } catch (_) {
      return null;
    }
  }

  /// Resolves any stored reference to a Firebase Storage object path, if possible.
  static String? resolveStorageReference(String? reference) {
    if (reference == null || reference.trim().isEmpty) {
      return null;
    }
    final trimmed = reference.trim();
    if (trimmed.startsWith('http')) {
      return storagePathFromDownloadUrl(trimmed);
    }
    return storageObjectPath(trimmed);
  }

  static String canonicalProfilePath(String userId) => 'profiles/$userId.jpg';

  /// Parses `profiles/{userId}.jpg` or legacy `profiles/{userId}_{timestamp}.jpg`.
  static String? userIdFromProfileStoragePath(String objectPath) {
    if (!objectPath.startsWith('profiles/')) {
      return null;
    }
    final fileName = objectPath.split('/').last;
    if (!fileName.endsWith('.jpg')) {
      return null;
    }
    var base = fileName.substring(0, fileName.length - 4);
    if (_legacyTimestampSuffix.hasMatch(fileName)) {
      final underscore = base.lastIndexOf('_');
      if (underscore > 0) {
        base = base.substring(0, underscore);
      }
    }
    return base.isEmpty ? null : base;
  }

  /// Paths to try when resolving a download URL (legacy path, then canonical).
  static List<String> resolveLookupPaths(String reference) {
    final primary = storageObjectPath(reference);
    final paths = <String>[primary];
    final userId = userIdFromProfileStoragePath(primary);
    if (userId != null) {
      final canonical = canonicalProfilePath(userId);
      if (!paths.contains(canonical)) {
        paths.add(canonical);
      }
    }
    return paths;
  }
}
