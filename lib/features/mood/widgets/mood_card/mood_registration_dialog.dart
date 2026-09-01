import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/mood/widgets/mood_card/level_card.dart';
import 'package:murmur/core/theme/app_theme.dart';
import 'package:murmur/l10n/app_localizations.dart';

class MoodRegistrationDialog extends StatefulWidget {
  final Emotion emotion;
  final List<String> userTriggers;
  final Function(num level, List<String> triggers,
      List<String> selectedTriggers, String? note) onSave;
  final int level;
  final List<String> selectedTriggers;
  final String note;
  final String heroTag;

  const MoodRegistrationDialog({
    super.key,
    required this.emotion,
    required this.userTriggers,
    required this.onSave,
    required this.level,
    required this.selectedTriggers,
    required this.note,
    required this.heroTag,
  });

  @override
  State<MoodRegistrationDialog> createState() => _MoodRegistrationDialogState();
}

class _MoodRegistrationDialogState extends State<MoodRegistrationDialog> {
  num _level = 1;
  List<String> _triggers = [];
  List<String> _selectedTriggers = [];
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _triggers = widget.userTriggers;
    _level = widget.level;
    _selectedTriggers = widget.selectedTriggers;
    _noteController.text = widget.note;
    mergeTriggers();
  }

  void mergeTriggers() {
    for (var trigger in _selectedTriggers) {
      if (!_triggers.contains(trigger)) {
        _triggers.add(trigger);
      }
    }
  }

  void _addTrigger(String tag) {
    if (!_triggers.contains(tag)) {
      setState(() {
        _triggers.add(tag);
        _selectedTriggers.add(tag);
      });
    }
  }

  void _showAddTagDialog(BuildContext context) {
    final textController = TextEditingController();
    final l10n = AppL10n.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addTrigger),
        // Обводку и заливку поля задаёт тема — раньше они были
        // переписаны здесь вручную и жили своей жизнью.
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            prefixText: '#',
            hintText: l10n.triggerHint,
          ),
          onSubmitted: (_) {
            _addTrigger(textController.text.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              _addTrigger(textController.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_noteFocusNode.hasFocus) {
          FocusScope.of(context).unfocus();
        } else {
          Navigator.pop(context);
        }
      },
      child: Material(
        // Затемнение, а не серая заливка: диалог должен читаться
        // как слой поверх экрана.
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: GestureDetector(
            onTap: () {
              if (_noteFocusNode.hasFocus) {
                FocusScope.of(context).unfocus();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: appCardDecoration(context, radius: AppRadius.xl),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: Text(
                          AppL10n.of(context).recordMood,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Interactive tap-slider
                    LevelCard(
                      initialLevel: _level,
                      label: widget.emotion.name,
                      emoji: widget.emotion.emoji,
                      heroTag: widget.heroTag,
                      onChanged: (newLevel) {
                        _level = newLevel;
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),

                    // Triggers chips
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 10,
                                children: [
                                  ..._triggers.map(
                                    (tag) {
                                      final selected =
                                          _selectedTriggers.contains(tag);
                                      final scheme =
                                          Theme.of(context).colorScheme;
                                      return InputChip(
                                        label: Text(tag),
                                        // Выбранный чип инвертируем: на
                                        // карточке полупрозрачная плёнка
                                        // почти не видна, а инверсия читается
                                        // в обеих темах.
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: selected
                                                  ? scheme.surface
                                                  : scheme.onSurfaceVariant,
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                        showCheckmark: false,
                                        selected: selected,
                                        onSelected: (value) {
                                          setState(() {
                                            value
                                                ? _selectedTriggers.add(tag)
                                                : _selectedTriggers.remove(tag);
                                          });
                                        },
                                        deleteIcon: Icon(Icons.close,
                                            size: 15,
                                            color: selected
                                                ? scheme.surface
                                                : scheme.onSurfaceVariant),
                                        onDeleted: () => setState(() {
                                          _triggers.remove(tag);
                                          _selectedTriggers.remove(tag);
                                        }),
                                        backgroundColor: Colors.transparent,
                                        selectedColor: scheme.onSurface
                                            .withValues(alpha: 0.92),
                                        side: BorderSide(
                                          color: selected
                                              ? Colors.transparent
                                              : scheme.outlineVariant,
                                        ),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: AppRadius.smAll,
                                        ),
                                      );
                                    },
                                  ),
                                  ActionChip(
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: AppRadius.smAll,
                                    ),
                                    labelStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    label: Text(
                                        AppL10n.of(context).addTriggerButton),
                                    onPressed: () => _showAddTagDialog(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),

                    // Note field
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        curve: Curves.easeInOut,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: 48,
                            maxHeight: 96,
                          ),
                          child: TextField(
                            controller: _noteController,
                            focusNode: _noteFocusNode,
                            decoration: InputDecoration(
                              hintText: AppL10n.of(context).addOptionalNote,
                              contentPadding:
                                  const EdgeInsets.all(AppSpacing.md),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            onChanged: (text) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {});
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          child: Text(AppL10n.of(context).cancel),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () {
                            widget.onSave(
                              _level,
                              _triggers,
                              _selectedTriggers,
                              _noteController.text.isEmpty
                                  ? null
                                  : _noteController.text,
                            );
                          },
                          child: Text(AppL10n.of(context).save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
