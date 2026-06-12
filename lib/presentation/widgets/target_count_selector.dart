import 'package:flutter/material.dart';

class TargetCountSelector extends StatelessWidget {
  const TargetCountSelector({
    super.key,
    required this.count,
    required this.onChanged,
    this.minValue = 1,
    this.maxValue = 10,
    this.colorHex = '#6750A4',
  });

  final int count;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: count > minValue
              ? () => onChanged(count - 1)
              : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(
            backgroundColor: accentColor.withOpacity(0.1),
            foregroundColor: accentColor,
            disabledBackgroundColor: theme.colorScheme.surface,
            disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.38),
          ),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text(
            count.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
        IconButton(
          onPressed: count < maxValue
              ? () => onChanged(count + 1)
              : null,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: accentColor.withOpacity(0.1),
            foregroundColor: accentColor,
            disabledBackgroundColor: theme.colorScheme.surface,
            disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.38),
          ),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }
}
