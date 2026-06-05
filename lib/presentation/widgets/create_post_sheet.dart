import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/core/extensions/context_extensions.dart';
import 'package:habitshare/core/utils/image_crop_utils.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/controllers/social_controller.dart';
import 'package:habitshare/presentation/providers/habit_provider.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key, required this.user});

  final UserEntity user;

  static Future<void> show(BuildContext context, {required UserEntity user}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CreatePostSheet(user: user),
    );
  }

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  String? _selectedHabitId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !mounted) {
        return;
      }
      final cropped = await ImageCropUtils.cropPostImage(picked.path);
      if (!mounted) {
        return;
      }
      if (cropped != null) {
        setState(() => _imageFile = cropped);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Could not open image picker. Please try again.',
          isError: true,
        );
      }
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      context.showSnackBar('Enter a post title', isError: true);
      return;
    }
    if (_selectedHabitId == null) {
      context.showSnackBar('Select a habit', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final error = await ref.read(socialControllerProvider).createPost(
          user: widget.user,
          habitId: _selectedHabitId!,
          title: title,
          message: _messageController.text.trim(),
          imageFile: _imageFile,
        );
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Post shared!');
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsStreamProvider(widget.user.id));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create post', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            habits.when(
              data: (items) {
                final active = items.where((h) => h.isActive).toList();
                if (active.isEmpty) {
                  return const Text('Create a habit first to share a post.');
                }
                _selectedHabitId ??= active.first.id;
                return DropdownButtonFormField<String>(
                  value: _selectedHabitId,
                  decoration: const InputDecoration(labelText: 'Habit'),
                  isExpanded: true,
                  items: active
                      .map(
                        (h) => DropdownMenuItem(
                          value: h.id,
                          child: Text(
                            h.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() => _selectedHabitId = value),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Could not load habits'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
              ),
              minLines: 2,
              maxLines: 4,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            if (_imageFile != null)
              AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label:
                  Text(_imageFile == null ? 'Add photo (4:5)' : 'Change photo'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
