import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/habit_controller.dart';

class CreateHabitDialog extends ConsumerStatefulWidget {
  const CreateHabitDialog({super.key, required this.user});

  final UserEntity user;

  @override
  ConsumerState<CreateHabitDialog> createState() => _CreateHabitDialogState();
}

class _CreateHabitDialogState extends ConsumerState<CreateHabitDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _messageController = TextEditingController();
  bool _shareAsPost = true;
  bool _isLoading = false;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  HabitFrequency _frequency = HabitFrequency.daily;

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
    final error = await ref.read(habitControllerProvider).createHabit(
          user: widget.user,
          title: title,
          description: _descriptionController.text,
          frequency: _frequency,
          shareAsPost: _shareAsPost,
          postMessage: _messageController.text,
          startDate: _startDate,
          endDate: _endDate,
        );

    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth > 600 ? 420.0 : screenWidth * 0.9;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          minWidth: dialogWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Habit', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
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
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _frequency = value);
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start date'),
                        subtitle: Text(AppDateUtils.formatDay(_startDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap:
                            _isLoading ? null : () => _pickDate(isStart: true),
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
                        onTap:
                            _isLoading ? null : () => _pickDate(isStart: false),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
