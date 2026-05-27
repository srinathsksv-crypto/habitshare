import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:habitshare/core/errors/exceptions.dart';
import 'package:habitshare/data/models/habit_model.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:uuid/uuid.dart';

class CsvDataSource {
  const CsvDataSource();

  static const _headers = [
    'title',
    'description',
    'color_hex',
    'frequency',
    'target_per_period',
  ];

  String exportHabits(List<HabitEntity> habits) {
    final rows = <List<dynamic>>[
      _headers,
      ...habits.map(
        (habit) => [
          habit.title,
          habit.description ?? '',
          habit.colorHex,
          habit.frequency.name,
          habit.targetPerPeriod,
        ],
      ),
    ];
    return csv.encode(rows);
  }

  List<HabitEntity> importHabits(String csvContent, String userId) {
    try {
      final rows = csv.decode(csvContent);
      if (rows.isEmpty) {
        return [];
      }
      final dataRows = rows.first == _headers ? rows.skip(1) : rows;
      const uuid = Uuid();
      final now = DateTime.now();
      return dataRows.map((row) {
        return HabitEntity(
          id: uuid.v4(),
          userId: userId,
          title: row[0].toString(),
          description: row.length > 1 ? row[1].toString() : null,
          colorHex: row.length > 2 ? row[2].toString() : '#6750A4',
          frequency: _parseFrequency(row.length > 3 ? row[3].toString() : 'daily'),
          targetPerPeriod: row.length > 4 ? int.tryParse(row[4].toString()) ?? 1 : 1,
          createdAt: now,
        );
      }).toList();
    } catch (e) {
      throw ValidationException('Invalid CSV format: $e');
    }
  }

  String encodeHabitForSync(HabitModel habit) => jsonEncode(habit.toJson());
}

HabitFrequency _parseFrequency(String value) =>
    HabitFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => HabitFrequency.daily,
    );
