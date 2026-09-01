import 'package:flutter/material.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/core/firebase/firebase_service.dart';
import 'package:murmur/features/mood/widgets/mood_card/mood_registration_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/l10n/app_localizations.dart';

Future<bool> showMoodRegistrationDialog({
  required BuildContext context,
  required AppUser appUser,
  required Emotion emotion,
  required WidgetRef ref,
  required List<String> selectedTriggers,
  int level = 1,
  String recordId = '',
  String note = '',
  required DateTime dateTime,
}) async {
  final result = await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: GestureDetector(
                onTap: () {}, // чтобы не закрывалось по тапу на контент
                child: FadeTransition(
                  opacity: animation,
                  child: MoodRegistrationDialog(
                    emotion: emotion,
                    userTriggers: appUser.triggers,
                    selectedTriggers: selectedTriggers,
                    heroTag: recordId,
                    onSave: (level, triggers, selectedTriggers, note) {
                      Navigator.of(ctx).pop({
                        'level': level,
                        'triggers': triggers,
                        'selectedTriggers': selectedTriggers,
                        'note': note,
                      });
                    },
                    level: level,
                    note: note,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  if (result is Map<String, dynamic>) {
    try {
      final List<String> selected = List.from(result['selectedTriggers'] ?? []);
      final List<String> all = List.from(result['triggers'] ?? []);

      final List<String> sortedTriggers = [
        ...selected,
        ...all.where((trigger) => !selected.contains(trigger)),
      ];

      final newIndex = await FirebaseService().saveMoodRecord(
        userId: appUser.id,
        emotion: emotion,
        recordId: recordId,
        level: result['level'],
        selectedTriggers: selected,
        userTriggers: sortedTriggers,
        note: result['note'],
        dateTime: dateTime,
      );
      ref.read(moodIndexProvider.notifier).state = newIndex;
      return true;
    } catch (e) {
      debugPrint('Error saving mood: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).failedToSaveMood)),
        );
      }
      return false;
    }
  } else {
    return false;
  }
}
