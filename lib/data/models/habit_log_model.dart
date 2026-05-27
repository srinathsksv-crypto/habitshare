import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:habitshare/domain/entities/habit_log_entity.dart';

part 'habit_log_model.freezed.dart';
part 'habit_log_model.g.dart';

@freezed
sealed class HabitLogModel with _$HabitLogModel {
  const factory HabitLogModel({
    required String id,
    @JsonKey(name: 'habit_id') required String habitId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'logged_at') required DateTime loggedAt,
    String? note,
    @Default(1) int value,
  }) = _HabitLogModel;

  factory HabitLogModel.fromJson(Map<String, dynamic> json) =>
      _$HabitLogModelFromJson(json);
}

extension HabitLogModelX on HabitLogModel {
  HabitLogEntity toEntity() => HabitLogEntity(
    id: id,
    habitId: habitId,
    userId: userId,
    loggedAt: loggedAt,
    note: note,
    value: value,
  );

  static HabitLogModel fromEntity(HabitLogEntity entity) => HabitLogModel(
    id: entity.id,
    habitId: entity.habitId,
    userId: entity.userId,
    loggedAt: entity.loggedAt,
    note: entity.note,
    value: entity.value,
  );
}
