import 'package:cloud_firestore/cloud_firestore.dart';

class MoodRecord {
  final String id;
  final String emotionId;
  final String name;
  final String emoji;
  final double coefficient;
  final int level;
  final double moodIndex;
  final List<String> selectedTriggers;
  final String note;
  final DateTime timestamp;
  final bool edited;

  MoodRecord({
    required this.id,
    required this.emotionId,
    required this.name,
    required this.emoji,
    required this.coefficient,
    required this.level,
    required this.moodIndex,
    required this.selectedTriggers,
    required this.note,
    required this.timestamp,
    required this.edited,
  });

  factory MoodRecord.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodRecord(
      id: doc.id,
      emotionId: data['emotionId'] ?? '',
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '',
      coefficient: (data['coefficient'] != null)
          ? (data['coefficient'] as num).toDouble()
          : 0.0001,
      level: (data['level'] as num).toInt(),
      moodIndex: (data['moodIndex'] as num).toDouble(),
      selectedTriggers: List<String>.from(data['selectedTriggers'] ?? []),
      note: data['note'] ?? '',
      timestamp: (data['timestamp'] != null && data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      edited: data['edited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emotionId': emotionId,
      'name': name,
      'emoji': emoji,
      'coefficient': coefficient,
      'level': level,
      'moodIndex': moodIndex,
      'selectedTriggers': selectedTriggers,
      'note': note,
      'timestamp': timestamp,
      'edited': edited,
    };
  }
}
