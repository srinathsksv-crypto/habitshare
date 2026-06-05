import 'package:equatable/equatable.dart';

enum HabitFrequency { daily, weekly, custom }

enum HabitStatus { active, quit, completed }

class HabitEntity extends Equatable {
  const HabitEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.categoryId,
    this.colorHex = '#6750A4',
    this.frequency = HabitFrequency.daily,
    this.targetPerPeriod = 1,
    this.isArchived = false,
    this.status = HabitStatus.active,
    this.startDate,
    this.endDate,
    this.updatedAt,
    this.streakCount = 0,
    this.lastCompletedAt,
    this.lastCompletedWindowIndex = 0,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? categoryId;
  final String colorHex;
  final HabitFrequency frequency;
  final int targetPerPeriod;
  final bool isArchived;
  final HabitStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int streakCount;
  final DateTime? lastCompletedAt;
  final int lastCompletedWindowIndex;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == HabitStatus.active && !isArchived;

  int? get durationInDays {
    final start = startDate ?? createdAt;
    final end = endDate;
    if (end == null) {
      return null;
    }
    return end.difference(start).inDays + 1;
  }

  HabitEntity copyWith({
    String? title,
    String? description,
    HabitStatus? status,
    bool? isArchived,
    int? streakCount,
    DateTime? lastCompletedAt,
    int? lastCompletedWindowIndex,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
  }) {
    return HabitEntity(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId,
      colorHex: colorHex,
      frequency: frequency,
      targetPerPeriod: targetPerPeriod,
      isArchived: isArchived ?? this.isArchived,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      streakCount: streakCount ?? this.streakCount,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      lastCompletedWindowIndex:
          lastCompletedWindowIndex ?? this.lastCompletedWindowIndex,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        categoryId,
        colorHex,
        frequency,
        targetPerPeriod,
        isArchived,
        status,
        startDate,
        endDate,
        streakCount,
        lastCompletedAt,
        lastCompletedWindowIndex,
        createdAt,
        updatedAt,
      ];
}

class HabitCategoryEntity extends Equatable {
  const HabitCategoryEntity({
    required this.id,
    required this.name,
    this.iconName,
  });

  final String id;
  final String name;
  final String? iconName;

  @override
  List<Object?> get props => [id, name, iconName];
}
