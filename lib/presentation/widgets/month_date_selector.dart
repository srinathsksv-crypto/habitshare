import 'package:flutter/material.dart';

class MonthDateSelector extends StatelessWidget {
  const MonthDateSelector({
    super.key,
    required this.selectedDates,
    required this.onChanged,
    this.colorHex = '#6750A4',
  });

  final List<int> selectedDates;
  final ValueChanged<List<int>> onChanged;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(31, (index) {
        final day = index + 1;
        final isSelected = selectedDates.contains(day);

        return FilterChip(
          label: Text(day.toString()),
          selected: isSelected,
          onSelected: (selected) {
            final newSelection = List<int>.from(selectedDates);
            if (selected) {
              newSelection.add(day);
            } else {
              newSelection.remove(day);
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
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }),
    );
  }
}
