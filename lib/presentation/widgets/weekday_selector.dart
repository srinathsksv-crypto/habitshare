import 'package:flutter/material.dart';

class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selectedWeekdays,
    required this.onChanged,
    this.colorHex = '#6750A4',
  });

  final List<int> selectedWeekdays;
  final ValueChanged<List<int>> onChanged;
  final String colorHex;

  static const List<String> _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final weekday = index + 1; // 1 = Monday, 7 = Sunday
          final isSelected = selectedWeekdays.contains(weekday);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_weekdayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<int>.from(selectedWeekdays);
                if (selected) {
                  newSelection.add(weekday);
                } else {
                  newSelection.remove(weekday);
                }
                onChanged(newSelection);
              },
              selectedColor: accentColor.withOpacity(0.2),
              checkmarkColor: accentColor,
              backgroundColor: theme.colorScheme.surface,
              labelStyle: TextStyle(
                color: isSelected ? accentColor : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? accentColor : theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}
