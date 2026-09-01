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
import 'package:murmur/l10n/app_localizations.dart';

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

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: appCardDecoration(context),
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
                  AppL10n.of(context).moodRecord,
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
                            items: [
                              PopupMenuItem(
                                value: 'edit',
                                height: 30,
                                child: SizedBox(
                                  width: 80,
                                  child: Text(AppL10n.of(context).edit,
                                      style: textTheme.bodyMedium),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                height: 30,
                                child: SizedBox(
                                  width: 80,
                                  child: Text(AppL10n.of(context).delete,
                                      style: textTheme.bodyMedium),
                                ),
                              ),
                            ],
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                                emotion: Emotion.fromMap(widget.record.toMap(),
                                    id: widget.record.emotionId),
                                ref: ref,
                                recordId: widget.record.id);
                            if (updtRequired) widget.update(true);
                          } else if (result == 'delete') {
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(AppL10n.of(context).deleteRecordQ),
                                content: Text(
                                    overflow: TextOverflow.clip,
                                    AppL10n.of(context).deleteRecordBody),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.error,
                                    ),
                                    child: Text(AppL10n.of(context).cancel),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      final firebaseService = FirebaseService();
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
                                    child: Text(AppL10n.of(context).delete),
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
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer.withAlpha(18),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Hero(
                                      tag:
                                          'mood-emoji-${widget.record.emoji}-${widget.record.id}',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          widget.record.emoji,
                                          style: const TextStyle(fontSize: 44),
                                          textScaler: TextScaler.linear(1.0),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md - 4),
                                    // Название и сила — теми же ролями, что
                                    // название и категория дорожки.
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Hero(
                                            tag:
                                                'mood-emoji-${widget.record.name}-text-${widget.record.id}',
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Text(
                                                widget.record.name,
                                                style: textTheme.bodyLarge
                                                    ?.copyWith(fontSize: 17),
                                                textScaler:
                                                    TextScaler.linear(1.0),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${AppL10n.of(context).levelLabel} ${widget.record.level.toStringAsFixed(0)}',
                                            style: textTheme.labelMedium,
                                            textScaler: TextScaler.linear(1.0),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppL10n.of(context).indexLabel,
                                          style: textTheme.labelMedium,
                                          textScaler: TextScaler.linear(1.0),
                                        ),
                                        Text(
                                          convertToIndex(
                                              widget.record.moodIndex),
                                          style: textTheme.bodyLarge
                                              ?.copyWith(fontSize: 20),
                                          textScaler: TextScaler.linear(1.0),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Подсказка в потоке, а не поверх строки:
                                // на компактной карточке она налезала.
                                Text(
                                  AppL10n.of(context).holdForOptions,
                                  style: textTheme.labelSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
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
              AppL10n.of(context).triggersLabel,
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
                                horizontal: 4, vertical: 2),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: Text(t, style: textTheme.labelMedium),
                            backgroundColor: Colors.transparent,
                            side: BorderSide(color: colorScheme.outlineVariant),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.smAll,
                            ),
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
              AppL10n.of(context).noteLabel,
              style: textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textScaler: TextScaler.linear(1.0),
            ),
            Text(
              widget.record.note,
              style: textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.linear(1.0),
            ),
          ],
        ],
      ),
    );
  }
}
