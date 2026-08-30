// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/mood/widgets/mood_card/show_reg_dialog.dart';
import 'package:murmur/core/widgets/saved_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/core/theme/app_theme.dart';

class MoodItem extends ConsumerWidget {
  final AppUser appUser;
  final Emotion emotion;
  final bool isSelected;

  const MoodItem({
    super.key,
    required this.appUser,
    required this.emotion,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (isSelected) {
            HapticFeedback.mediumImpact();
            FirebaseService.logEvent('mooditem_pressed');
            bool saved = await showMoodRegistrationDialog(
              context: context,
              appUser: appUser,
              emotion: emotion,
              ref: ref,
              selectedTriggers: [],
              dateTime: DateTime.now(),
            );

            if (saved) {
              showSuccessOverlay(context);
            }
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - 312) / 2,
            ),
            Column(
              children: [
                Hero(
                  tag: 'mood-emoji-${emotion.emoji}-',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      emotion.emoji,
                      style: const TextStyle(fontSize: 80),
                      textScaler: TextScaler.linear(1.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 30),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 200),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'mood-emoji-${emotion.name}-text-',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        emotion.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                            ),
                        textScaler: TextScaler.linear(1.0),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Text(
                    emotion.description,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                    textScaler: TextScaler.linear(1.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
