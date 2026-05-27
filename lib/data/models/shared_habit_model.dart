import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:habitshare/domain/entities/shared_habit_entity.dart';

part 'shared_habit_model.freezed.dart';
part 'shared_habit_model.g.dart';

@freezed
sealed class SharedHabitModel with _$SharedHabitModel {
  const factory SharedHabitModel({
    required String id,
    @JsonKey(name: 'habit_id') required String habitId,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'shared_with_user_id') required String sharedWithUserId,
    @JsonKey(name: 'shared_at') required DateTime sharedAt,
    String? message,
  }) = _SharedHabitModel;

  factory SharedHabitModel.fromJson(Map<String, dynamic> json) =>
      _$SharedHabitModelFromJson(json);
}

extension SharedHabitModelX on SharedHabitModel {
  SharedHabitEntity toEntity() => SharedHabitEntity(
    id: id,
    habitId: habitId,
    ownerId: ownerId,
    sharedWithUserId: sharedWithUserId,
    sharedAt: sharedAt,
    message: message,
  );

  static SharedHabitModel fromEntity(SharedHabitEntity entity) =>
      SharedHabitModel(
        id: entity.id,
        habitId: entity.habitId,
        ownerId: entity.ownerId,
        sharedWithUserId: entity.sharedWithUserId,
        sharedAt: entity.sharedAt,
        message: entity.message,
      );
}
