import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/mood/models/mood_record.dart';
import 'package:murmur/features/mood/widgets/mood_card/show_reg_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/core/theme/app_theme.dart';

class MoodRecordCard extends ConsumerStatefulWidget {
  final MoodRecord record;
  final AppUser appUser;
  final Function(bool) update;
  const MoodRecordCard(
      {super.key,
      required this.record,
      required this.appUser,
      required this.update});

  @override
  ConsumerState<MoodRecordCard> createState() => MoodRecordCardState();
}

class MoodRecordCardState extends ConsumerState<MoodRecordCard> {
  String convertToIndex(double moodValue) {
    final index = ((moodValue + 1) / 2) * 100;
    return index.round().clamp(0, 100).toString();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final fillPercent = (widget.record.level / 10).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mood Record',
                    style: textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textScaler: TextScaler.linear(1.0),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(
                      widget.record.timestamp,
                    ),
                    style: textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textScaler: TextScaler.linear(1.0),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            //colors/level/emotion/index
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Stack(
                children: [
                  // Color level
                  Positioned.fill(
                    child: Row(
                      children: [
                        // Filled part
                        Expanded(
                          flex: (fillPercent * 1000).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        // Notfilled part
                        Expanded(
                          flex: 1000 - (fillPercent * 1000).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.record.level < 10
                                      ? colorScheme.secondary
                                      : colorScheme.primary,
                                  widget.record.level < 10
                                      ? colorScheme.onPrimaryFixed
                                      : colorScheme.secondary,
                                ],
                                // stops: [0.0, 0.95, 1.0],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //Content
                  Stack(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: GestureDetector(
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            HapticFeedback.mediumImpact();
                            final result = await showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                                MediaQuery.of(context).size.width -
                                    details.globalPosition.dx,
                                MediaQuery.of(context).size.height -
                                    details.globalPosition.dy,
                              ),
                              items: const [
                                PopupMenuItem(
                                  value: 'edit',
                                  height: 30,
                                  child: SizedBox(
                                    width: 80,
                                    child: Text('Edit',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  height: 30,
                                  child: SizedBox(
                                    width: 80,
                                    child: Text('Delete',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                              ],
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            );
                            if (!context.mounted) return;
                            bool updtRequired = false;
                            if (result == 'edit') {
                              updtRequired = await showMoodRegistrationDialog(
                                  level: widget.record.level,
                                  selectedTriggers:
                                      widget.record.selectedTriggers,
                                  note: widget.record.note,
                                  dateTime: widget.record.timestamp,
                                  context: context, //ошбка тут
                                  appUser: widget.appUser,
                                  emotion: Emotion.fromMap(
                                      widget.record.toMap(),
                                      id: widget.record.emotionId),
                                  ref: ref,
                                  recordId: widget.record.id);
                              if (updtRequired) widget.update(true);
                            } else if (result == 'delete') {
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete record?'),
                                  content: const Text(
                                      overflow: TextOverflow.clip,
                                      'This action will permanently delete this Mood Record'),
                                  actions: [
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        foregroundColor:
                                            Theme.of(context).colorScheme.error,
                                        backgroundColor: Colors.transparent,
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontSize: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        final firebaseService =
                                            FirebaseService();
                                        final newIndex = await firebaseService
                                            .deleteMoodRecord(
                                          widget.appUser.id,
                                          widget.record.id,
                                        );
                                        updtRequired = newIndex != null;
                                        if (newIndex != null) {
                                          ref
                                              .read(moodIndexProvider.notifier)
                                              .state = newIndex;
                                          widget.update(false);
                                        }

                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                      },
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        backgroundColor: Colors.transparent,
                                      ),
                                      child: Text(
                                        'Delete',
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
                          },
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            onTap: () {},
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.surfaceContainer.withAlpha(18),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const SizedBox(width: 12),

                                      Hero(
                                        tag:
                                            'mood-emoji-${widget.record.emoji}-${widget.record.id}',
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            widget.record.emoji,
                                            style:
                                                const TextStyle(fontSize: 60),
                                            textScaler: TextScaler.linear(1.0),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Level and emotion name
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                170),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Material(
                                              color: Colors.transparent,
                                              child: Hero(
                                                tag:
                                                    'mood-emoji-${widget.record.name}-text-${widget.record.id}',
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: Text(
                                                    widget.record.name,
                                                    style: textTheme.titleLarge
                                                        ?.copyWith(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textScaler:
                                                        TextScaler.linear(1.0),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Level: ${widget.record.level.toStringAsFixed(0)}',
                                              style: textTheme.titleLarge
                                                  ?.copyWith(
                                                fontSize: 18,
                                              ),
                                              textScaler:
                                                  TextScaler.linear(1.0),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(child: SizedBox.shrink()),

                                      //recrod index
                                      ConstrainedBox(
                                        constraints:
                                            BoxConstraints(maxWidth: 170),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Index:',
                                              style: textTheme.titleLarge
                                                  ?.copyWith(
                                                fontSize: 18,
                                              ),
                                              textScaler:
                                                  TextScaler.linear(1.0),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              convertToIndex(
                                                  widget.record.moodIndex),
                                              style: textTheme.titleMedium
                                                  ?.copyWith(fontSize: 24),
                                              overflow: TextOverflow.ellipsis,
                                              textScaler:
                                                  TextScaler.linear(1.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 3,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hold for options',
                              style: textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Triggers (if any)
            if (widget.record.selectedTriggers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Triggers:',
                style: textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textScaler: TextScaler.linear(1.0),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: widget.record.selectedTriggers
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(
                                right: 6), // spacing between chips
                            child: Chip(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 4),
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                t,
                                style: textTheme.bodyMedium,
                              ),
                              backgroundColor: colorScheme.primaryContainer,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 2),
            // Note
            if (widget.record.note.isNotEmpty) ...[
              Text(
                'Note:',
                style: textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textScaler: TextScaler.linear(1.0),
              ),
              Text(
                widget.record.note,
                style: textTheme.labelMedium?.copyWith(
                  // color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.linear(1.0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
