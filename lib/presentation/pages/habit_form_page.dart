import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/habit_controller.dart';
import 'package:habitshare/presentation/widgets/month_date_selector.dart';
import 'package:habitshare/presentation/widgets/target_count_selector.dart';
import 'package:habitshare/presentation/widgets/weekday_selector.dart';

class HabitFormPage extends ConsumerStatefulWidget {
  const HabitFormPage({
    super.key,
    required this.user,
    this.habit,
  });

  final UserEntity user;
  final HabitEntity? habit;

  @override
  ConsumerState<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends ConsumerState<HabitFormPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _messageController = TextEditingController();
  bool _shareAsPost = true;
  bool _isLoading = false;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  HabitFrequency _frequency = HabitFrequency.daily;
  List<int> _selectedWeekdays = [];
  List<int> _selectedMonthDates = [];
  int _targetCount = 1;
  String _colorHex = '#6750A4';

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      debugPrint('Edit Habit - ID: ${widget.habit!.id}');
      debugPrint('Edit Habit - Title: ${widget.habit!.title}');

      // Populate fields from habit
      _titleController.text = widget.habit!.title;
      _descriptionController.text = widget.habit!.description ?? '';
      _colorHex = widget.habit!.colorHex;
      _frequency = widget.habit!.frequency;
      _selectedWeekdays = widget.habit!.selectedWeekdays ?? [];
      _selectedMonthDates = widget.habit!.selectedMonthDates ?? [];
      _targetCount = widget.habit!.targetCount ?? 1;
      _startDate = widget.habit!.startDate ?? DateTime.now();
      _endDate = widget.habit!.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      context.showSnackBar('Please enter a habit title', isError: true);
      return;
    }
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      context.showSnackBar('End date must be after start date', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    String? error;
    if (widget.habit == null) {
      // Create mode
      error = await ref.read(habitControllerProvider).createHabit(
            user: widget.user,
            title: title,
            description: _descriptionController.text,
            frequency: _frequency,
            selectedWeekdays: _frequency == HabitFrequency.weekdays
                ? _selectedWeekdays
                : null,
            selectedMonthDates: _frequency == HabitFrequency.monthlyDates
                ? _selectedMonthDates
                : null,
            targetCount: (_frequency == HabitFrequency.timesPerWeek ||
                    _frequency == HabitFrequency.timesPerMonth)
                ? _targetCount
                : null,
            shareAsPost: _shareAsPost,
            postMessage: _messageController.text,
            startDate: _startDate,
            endDate: _endDate,
          );
    } else {
      // Edit mode
      error = await ref.read(habitControllerProvider).updateHabit(
            habit: widget.habit!,
            title: title,
            description: _descriptionController.text,
            frequency: _frequency,
            selectedWeekdays: _frequency == HabitFrequency.weekdays
                ? _selectedWeekdays
                : null,
            selectedMonthDates: _frequency == HabitFrequency.monthlyDates
                ? _selectedMonthDates
                : null,
            targetCount: (_frequency == HabitFrequency.timesPerWeek ||
                    _frequency == HabitFrequency.timesPerMonth)
                ? _targetCount
                : null,
            startDate: _startDate,
            endDate: _endDate,
            colorHex: _colorHex,
          );
    }

    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }

    if (widget.habit != null) {
      // Return updated habit for edit mode
      // Construct directly to avoid copyWith null coalescing issue
      final updatedHabit = HabitEntity(
        id: widget.habit!.id,
        userId: widget.habit!.userId,
        title: title,
        description: _descriptionController.text,
        categoryId: widget.habit!.categoryId,
        colorHex: _colorHex,
        frequency: _frequency,
        targetPerPeriod: widget.habit!.targetPerPeriod,
        selectedWeekdays:
            _frequency == HabitFrequency.weekdays ? _selectedWeekdays : null,
        selectedMonthDates: _frequency == HabitFrequency.monthlyDates
            ? _selectedMonthDates
            : null,
        targetCount: (_frequency == HabitFrequency.timesPerWeek ||
                _frequency == HabitFrequency.timesPerMonth)
            ? _targetCount
            : null,
        isArchived: widget.habit!.isArchived,
        status: widget.habit!.status,
        startDate: _startDate,
        endDate: _endDate,
        streakCount: widget.habit!.streakCount,
        lastCompletedAt: widget.habit!.lastCompletedAt,
        lastCompletedWindowIndex: widget.habit!.lastCompletedWindowIndex,
        currentPeriodCompletionCount:
            widget.habit!.currentPeriodCompletionCount,
        createdAt: widget.habit!.createdAt,
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(updatedHabit);
    } else {
      // Return true for create mode
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Create Habit' : 'Edit Habit'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Habit title *',
                  hintText: 'e.g. Morning run',
                ),
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What are you tracking?',
                  alignLabelWithHint: true,
                ),
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HabitFrequency>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency *',
                  hintText: 'How often do you want to do this?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: HabitFrequency.daily,
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: HabitFrequency.weekly,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: HabitFrequency.weekdays,
                    child: Text('Specific Weekdays'),
                  ),
                  DropdownMenuItem(
                    value: HabitFrequency.monthlyDates,
                    child: Text('Specific Dates of Month'),
                  ),
                  DropdownMenuItem(
                    value: HabitFrequency.timesPerWeek,
                    child: Text('X Times Per Week'),
                  ),
                  DropdownMenuItem(
                    value: HabitFrequency.timesPerMonth,
                    child: Text('X Times Per Month'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _frequency = value;
                            _selectedWeekdays = [];
                            _selectedMonthDates = [];
                            _targetCount = 1;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              if (_frequency == HabitFrequency.weekdays) ...[
                const Text('Select Weekdays'),
                const SizedBox(height: 8),
                WeekdaySelector(
                  selectedWeekdays: _selectedWeekdays,
                  onChanged: (value) =>
                      setState(() => _selectedWeekdays = value),
                ),
                const SizedBox(height: 12),
              ],
              if (_frequency == HabitFrequency.monthlyDates) ...[
                const Text('Select Dates'),
                const SizedBox(height: 8),
                MonthDateSelector(
                  selectedDates: _selectedMonthDates,
                  onChanged: (value) =>
                      setState(() => _selectedMonthDates = value),
                ),
                const SizedBox(height: 12),
              ],
              if (_frequency == HabitFrequency.timesPerWeek ||
                  _frequency == HabitFrequency.timesPerMonth) ...[
                const Text('Target Count'),
                const SizedBox(height: 8),
                TargetCountSelector(
                  count: _targetCount,
                  onChanged: (value) => setState(() => _targetCount = value),
                ),
                const SizedBox(height: 12),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start date'),
                subtitle: Text(AppDateUtils.formatDay(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isLoading ? null : () => _pickDate(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End date (optional)'),
                subtitle: Text(
                  _endDate != null
                      ? AppDateUtils.formatDay(_endDate!)
                      : 'No end date',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_endDate != null)
                      IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _endDate = null),
                        icon: const Icon(Icons.clear),
                      ),
                    const Icon(Icons.event),
                  ],
                ),
                onTap: _isLoading ? null : () => _pickDate(isStart: false),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share as post'),
                subtitle: const Text(
                  'Visible to followers after they accept your requests',
                ),
                value: _shareAsPost,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _shareAsPost = value),
              ),
              if (_shareAsPost) ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Post message (optional)',
                    hintText: 'Motivate your followers...',
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  minLines: 2,
                  maxLines: 4,
                  enabled: !_isLoading,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.habit == null ? 'Create' : 'Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
