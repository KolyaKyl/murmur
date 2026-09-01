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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        title: Text(AppL10n.of(context).addTrigger),
        content: TextField(
          cursorColor: Theme.of(context).colorScheme.onSurface,
          controller: textController,
          decoration: InputDecoration(
            prefixText: '#',
            hintText: AppL10n.of(context).triggerHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
            contentPadding: const EdgeInsets.all(8),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundColor: Theme.of(context).colorScheme.error,
              backgroundColor: Colors.transparent,
            ),
            child: Text(
              AppL10n.of(context).cancel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _addTrigger('#${textController.text.trim()}');
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Colors.transparent,
            ),
            child: Text(
              AppL10n.of(context).add,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 18),
            ),
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
        color: Theme.of(context).colorScheme.surfaceBright,
        child: Center(
          child: GestureDetector(
            onTap: () {
              if (_noteFocusNode.hasFocus) {
                FocusScope.of(context).unfocus();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Text(
                      AppL10n.of(context).recordMood,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(
                      height: 6,
                    ),

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
                                    (tag) => InputChip(
                                      label: Text(
                                        tag,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      showCheckmark: false,
                                      selected: _selectedTriggers.contains(tag),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedTriggers.add(tag);
                                          } else {
                                            _selectedTriggers.remove(tag);
                                          }
                                        });
                                      },
                                      deleteIcon: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      onDeleted: () => setState(() {
                                        _triggers.remove(tag);
                                        _selectedTriggers.remove(tag);
                                      }),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                      selectedColor:
                                          Theme.of(context).colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                      ),
                                    ),
                                  ),
                                  ActionChip(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
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
                            cursorColor:
                                Theme.of(context).colorScheme.onSurface,
                            controller: _noteController,
                            focusNode: _noteFocusNode,
                            decoration: InputDecoration(
                              hintText: AppL10n.of(context).addOptionalNote,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              contentPadding: const EdgeInsets.all(16),
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

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            AppL10n.of(context).cancel,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
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
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            AppL10n.of(context).save,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 18),
                          ),
                        ),
                      ],
                    )
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
