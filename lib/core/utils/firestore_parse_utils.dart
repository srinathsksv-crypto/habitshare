import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreParseUtils {
  FirestoreParseUtils._();

  static DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
    if (value == null) {
      return fallback ?? DateTime.now();
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return fallback ?? DateTime.now();
  }

  static DateTime? parseDateTimeOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    return parseDateTime(value);
  }

  static Map<String, dynamic> normalizeDoc(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return {...data, 'id': id};
  }
}
