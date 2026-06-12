import 'package:equatable/equatable.dart';

class HabitLogEntity extends Equatable {
  const HabitLogEntity({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.loggedAt,
    this.note,
    this.value = 1,
    this.windowIndex,
  });

  final String id;
  final String habitId;
  final String userId;
  final DateTime loggedAt;
  final String? note;
  final int value;
  final int? windowIndex;

  @override
  List<Object?> get props =>
      [id, habitId, userId, loggedAt, note, value, windowIndex];
}
