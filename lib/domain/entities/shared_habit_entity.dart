import 'package:equatable/equatable.dart';

class SharedHabitEntity extends Equatable {
  const SharedHabitEntity({
    required this.id,
    required this.habitId,
    required this.ownerId,
    required this.sharedWithUserId,
    required this.sharedAt,
    this.message,
  });

  final String id;
  final String habitId;
  final String ownerId;
  final String sharedWithUserId;
  final DateTime sharedAt;
  final String? message;

  @override
  List<Object?> get props => [
    id,
    habitId,
    ownerId,
    sharedWithUserId,
    sharedAt,
    message,
  ];
}
