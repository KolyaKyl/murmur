import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:murmur/features/breathing/models/practice.dart';
import 'package:murmur/core/models/catalog_category.dart';

class BreathingRepository {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<CatalogCategory>> fetchCategories() async {
    final snap =
        await _db.collection('breathingCategories').orderBy('order').get();
    return snap.docs.map(CatalogCategory.fromDoc).toList();
  }

  Future<List<BreathingPractice>> fetchPractices() async {
    final snap =
        await _db.collection('breathingPractices').orderBy('order').get();
    return snap.docs.map(BreathingPractice.fromDoc).toList();
  }

  DocumentReference<Map<String, dynamic>>? get _statsDoc {
    final uid = _uid;
    return uid == null
        ? null
        : _db.collection('users').doc(uid).collection('stats').doc('breathing');
  }

  Future<BreathingStats> fetchStats() async {
    final doc = _statsDoc;
    if (doc == null) return const BreathingStats();
    final snap = await doc.get();
    return snap.exists ? BreathingStats.fromDoc(snap) : const BreathingStats();
  }

  /// Пишем в конце практики: журнал сессии и пересчитанная сводка.
  /// Серию считаем здесь, а не при чтении, — иначе экран статистики
  /// пришлось бы каждый раз перебирать все сессии.
  Future<BreathingStats> recordSession({
    required String practiceId,
    required int cycles,
    required int seconds,
  }) async {
    final uid = _uid;
    final stats = _statsDoc;
    if (uid == null || stats == null) return const BreathingStats();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('breathingSessions')
          .add({
        'practiceId': practiceId,
        'cycles': cycles,
        'seconds': seconds,
        'finishedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      debugPrint('breathing session log failed: $e');
    }

    final previous = await fetchStats();
    final last = previous.lastSessionDate;
    final lastDay =
        last == null ? null : DateTime(last.year, last.month, last.day);

    final int streak;
    if (lastDay == null) {
      streak = 1;
    } else if (lastDay == today) {
      // Вторая практика за день серию не наращивает.
      streak = previous.currentStreak == 0 ? 1 : previous.currentStreak;
    } else if (today.difference(lastDay).inDays == 1) {
      streak = previous.currentStreak + 1;
    } else {
      streak = 1;
    }

    final next = BreathingStats(
      totalSessions: previous.totalSessions + 1,
      totalSeconds: previous.totalSeconds + seconds,
      currentStreak: streak,
      longestStreak:
          streak > previous.longestStreak ? streak : previous.longestStreak,
      lastSessionDate: now,
    );

    await stats.set({
      'totalSessions': next.totalSessions,
      'totalSeconds': next.totalSeconds,
      'currentStreak': next.currentStreak,
      'longestStreak': next.longestStreak,
      'lastSessionDate': Timestamp.fromDate(now),
      'byPractice': {practiceId: FieldValue.increment(1)},
    }, SetOptions(merge: true));

    return next;
  }
}
