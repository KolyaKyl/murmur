import 'package:cloud_firestore/cloud_firestore.dart';

/// Фаза дыхательного цикла. Порядок — порядок в цикле.
enum BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathingPractice {
  const BreathingPractice({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.inhale,
    required this.holdIn,
    required this.exhale,
    required this.holdOut,
    required this.categories,
    required this.premium,
    required this.order,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;

  /// Секунды. Ноль означает, что фазы в этом ритме нет вовсе —
  /// у когерентного дыхания задержек не бывает.
  final int inhale;
  final int holdIn;
  final int exhale;
  final int holdOut;

  /// Ситуации: sleep, calm, focus, recover, healing.
  final List<String> categories;
  final bool premium;
  final int order;

  int get cycleSeconds => inhale + holdIn + exhale + holdOut;

  /// Только те фазы, что реально есть в ритме.
  List<({BreathPhase phase, int seconds})> get phases => [
        (phase: BreathPhase.inhale, seconds: inhale),
        (phase: BreathPhase.holdIn, seconds: holdIn),
        (phase: BreathPhase.exhale, seconds: exhale),
        (phase: BreathPhase.holdOut, seconds: holdOut),
      ].where((p) => p.seconds > 0).toList();

  /// «4 · 7 · 8» — только непустые фазы, как их и читают вслух.
  String get rhythm => phases.map((p) => p.seconds).join(' · ');

  /// Сколько полных циклов уложится в выбранное время.
  /// Округляем к ближайшему: сессия всегда кончается полным выдохом,
  /// а реальную длительность показываем рядом, чтобы не было обмана.
  int cyclesFor(Duration target) {
    if (cycleSeconds <= 0) return 1;
    final n = (target.inSeconds / cycleSeconds).round();
    return n < 1 ? 1 : n;
  }

  Duration durationFor(int cycles) => Duration(seconds: cycles * cycleSeconds);

  factory BreathingPractice.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    int i(String k) => (d[k] as num?)?.toInt() ?? 0;
    return BreathingPractice(
      id: doc.id,
      title: d['title'] as String? ?? '',
      subtitle: d['subtitle'] as String? ?? '',
      description: d['description'] as String? ?? '',
      inhale: i('inhale'),
      holdIn: i('holdIn'),
      exhale: i('exhale'),
      holdOut: i('holdOut'),
      categories: (d['categories'] as List?)?.cast<String>() ?? const [],
      premium: d['premium'] as bool? ?? false,
      order: i('order'),
    );
  }
}

/// Сводка по дыханию. Один документ вместо перечитывания всех сессий:
/// серию дней и итоги считаем в конце практики и храним готовыми.
class BreathingStats {
  const BreathingStats({
    this.totalSessions = 0,
    this.totalSeconds = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastSessionDate,
  });

  final int totalSessions;
  final int totalSeconds;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastSessionDate;

  int get totalMinutes => totalSeconds ~/ 60;

  factory BreathingStats.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    int i(String k) => (d[k] as num?)?.toInt() ?? 0;
    return BreathingStats(
      totalSessions: i('totalSessions'),
      totalSeconds: i('totalSeconds'),
      currentStreak: i('currentStreak'),
      longestStreak: i('longestStreak'),
      lastSessionDate: (d['lastSessionDate'] as Timestamp?)?.toDate(),
    );
  }
}
