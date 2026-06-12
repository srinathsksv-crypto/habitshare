import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:habitshare/core/utils/date_utils.dart';
import 'package:habitshare/domain/entities/habit_entity.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/domain/services/habit_scheduler_service.dart';
import 'package:habitshare/domain/services/habit_streak_service.dart';
import 'package:habitshare/presentation/screens/habit_details_screen.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.user,
    this.onTap,
    this.onComplete,
  });

  final HabitEntity habit;
  final UserEntity user;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = habit.startDate ?? habit.createdAt;
    final end = habit.endDate;
    final durationLabel = habit.durationInDays != null
        ? '${habit.durationInDays} days'
        : 'Ongoing';
    final now = DateTime.now();
    final canComplete = HabitStreakService.canCompleteHabit(habit, now);
    final completionStatus = HabitStreakService.getCompletionStatus(habit, now);
    final eligibilityMessage =
        HabitStreakService.getCompletionEligibilityMessage(habit, now);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HabitDetailsScreen(habit: habit, user: user),
                ),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      habit.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (!habit.isActive)
                    Chip(
                      label: Text(habit.status.name),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (habit.description?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  habit.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      end != null
                          ? '${AppDateUtils.formatDay(start)} → ${AppDateUtils.formatDay(end)}'
                          : 'Since ${AppDateUtils.formatDay(start)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    durationLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    HabitSchedulerService.getFrequencyDisplayText(habit),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (habit.streakCount > 1)
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.streakCount}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (onComplete != null)
                SwipeToCompleteButton(
                  canComplete: canComplete,
                  completionStatus: completionStatus,
                  eligibilityMessage: eligibilityMessage,
                  onComplete: onComplete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwipeToCompleteButton extends StatefulWidget {
  const SwipeToCompleteButton({
    super.key,
    required this.canComplete,
    required this.completionStatus,
    required this.eligibilityMessage,
    required this.onComplete,
  });

  final bool canComplete;
  final String completionStatus;
  final String eligibilityMessage;
  final VoidCallback? onComplete;

  @override
  State<SwipeToCompleteButton> createState() => _SwipeToCompleteButtonState();
}

class _SwipeToCompleteButtonState extends State<SwipeToCompleteButton>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _chevronAnimationController;
  bool _isCompleted = false;
  double _dragOffset = 0.0;
  double _totalWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _isCompleted = false;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _chevronAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SwipeToCompleteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No need to update _isCompleted based on canComplete
    // _isCompleted should only change when user actually completes the habit
  }

  @override
  void dispose() {
    _progressController.dispose();
    _chevronAnimationController.dispose();
    super.dispose();
  }

  double _getChevronOpacity(double t, int index) {
    final double offset = index * 0.2;
    final double progress = (t - offset) % 1.0;
    if (progress < 0.4) {
      final double normalized = progress / 0.4;
      final double sinVal = math.sin(normalized * math.pi);
      return 0.25 + 0.75 * sinVal;
    } else {
      return 0.25;
    }
  }

  Widget _buildChevron(int index) {
    return AnimatedBuilder(
      animation: _chevronAnimationController,
      builder: (context, child) {
        final opacity = _isCompleted
            ? 0.4
            : _getChevronOpacity(_chevronAnimationController.value, index);
        return Opacity(
          opacity: opacity,
          child: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 28,
          ),
        );
      },
    );
  }

  void _onDragStart(DragStartDetails details) {
    if (_isCompleted) return;
    _dragOffset = _progressController.value * _totalWidth;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;
    _dragOffset += details.delta.dx;
    final progress = (_dragOffset / _totalWidth).clamp(0.0, 1.0);
    _progressController.value = progress;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isCompleted) return;
    const threshold = 0.75;
    if (_progressController.value >= threshold) {
      setState(() {
        _isCompleted = true;
      });
      _progressController
          .animateTo(
        1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      )
          .then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    } else {
      _progressController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      _dragOffset = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final completedColor = Colors.grey.shade400;
    final disabledColor = Colors.grey.shade600;

    final showEligibilityMessage =
        !widget.canComplete && widget.eligibilityMessage.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        _totalWidth = constraints.maxWidth;
        const chevronWidth = 52.0;
        const padding = 10.0;

        return GestureDetector(
          onHorizontalDragStart: _isCompleted ? null : _onDragStart,
          onHorizontalDragUpdate: _isCompleted ? null : _onDragUpdate,
          onHorizontalDragEnd: _isCompleted ? null : _onDragEnd,
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final progress = _progressController.value;
              final currentBgColor = showEligibilityMessage
                  ? disabledColor
                  : Color.lerp(primaryColor, completedColor, progress) ??
                      primaryColor;
              final leftPosition = padding +
                  progress * (_totalWidth - chevronWidth - 2 * padding);

              final textWidget = _isCompleted
                  ? const Text(
                      'Completed',
                      key: ValueKey('completed'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    )
                  : showEligibilityMessage
                      ? Text(
                          widget.eligibilityMessage,
                          key: ValueKey('ineligible'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        )
                      : Opacity(
                          opacity: (1.0 - progress * 2.0).clamp(0.0, 1.0),
                          child: const Text(
                            'Swipe to Complete',
                            key: ValueKey('swipe'),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );

              return Container(
                height: 48,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: currentBgColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: showEligibilityMessage
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_isCompleted && !showEligibilityMessage)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: progress * _totalWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomLeft: Radius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: textWidget,
                      ),
                    ),
                    if (!showEligibilityMessage)
                      Positioned(
                        left: leftPosition,
                        child: SizedBox(
                          width: chevronWidth,
                          height: 28,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: _buildChevron(0),
                              ),
                              Positioned(
                                left: 12,
                                top: 0,
                                bottom: 0,
                                child: _buildChevron(1),
                              ),
                              Positioned(
                                left: 24,
                                top: 0,
                                bottom: 0,
                                child: _buildChevron(2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
