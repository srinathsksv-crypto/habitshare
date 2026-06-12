import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';

part 'habit_model.freezed.dart';
part 'habit_model.g.dart';

@freezed
sealed class HabitModel with _$HabitModel {
  const factory HabitModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    String? description,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'color_hex') @Default('#6750A4') String colorHex,
    @Default('daily') String frequency,
    @JsonKey(name: 'target_per_period') @Default(1) int targetPerPeriod,
    @JsonKey(name: 'selected_weekdays') List<int>? selectedWeekdays,
    @JsonKey(name: 'selected_month_dates') List<int>? selectedMonthDates,
    @JsonKey(name: 'target_count') int? targetCount,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
    @Default('active') String status,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'streak_count') @Default(0) int streakCount,
    @JsonKey(name: 'last_completed_at') DateTime? lastCompletedAt,
    @JsonKey(name: 'last_completed_window_index')
    @Default(0)
    int lastCompletedWindowIndex,
    @JsonKey(name: 'current_period_completion_count')
    @Default(0)
    int currentPeriodCompletionCount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _HabitModel;

  factory HabitModel.fromJson(Map<String, dynamic> json) =>
      _$HabitModelFromJson(json);
}

extension HabitModelX on HabitModel {
  HabitEntity toEntity() => HabitEntity(
        id: id,
        userId: userId,
        title: title,
        description: description,
        categoryId: categoryId,
        colorHex: colorHex,
        frequency: _parseFrequency(frequency),
        targetPerPeriod: targetPerPeriod,
        selectedWeekdays: selectedWeekdays,
        selectedMonthDates: selectedMonthDates,
        targetCount: targetCount,
        isArchived: isArchived,
        status: _parseStatus(status),
        startDate: startDate ?? createdAt,
        endDate: endDate,
        streakCount: streakCount,
        lastCompletedAt: lastCompletedAt,
        lastCompletedWindowIndex: lastCompletedWindowIndex,
        currentPeriodCompletionCount: currentPeriodCompletionCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static HabitModel fromEntity(HabitEntity entity) => HabitModel(
        id: entity.id,
        userId: entity.userId,
        title: entity.title,
        description: entity.description,
        categoryId: entity.categoryId,
        colorHex: entity.colorHex,
        frequency: entity.frequency.name,
        targetPerPeriod: entity.targetPerPeriod,
        selectedWeekdays: entity.selectedWeekdays,
        selectedMonthDates: entity.selectedMonthDates,
        targetCount: entity.targetCount,
        isArchived: entity.isArchived,
        status: entity.status.name,
        startDate: entity.startDate,
        endDate: entity.endDate,
        streakCount: entity.streakCount,
        lastCompletedAt: entity.lastCompletedAt,
        lastCompletedWindowIndex: entity.lastCompletedWindowIndex,
        currentPeriodCompletionCount: entity.currentPeriodCompletionCount,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}

HabitFrequency _parseFrequency(String value) =>
    HabitFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => HabitFrequency.daily,
    );

HabitStatus _parseStatus(String value) => HabitStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => HabitStatus.active,
    );
