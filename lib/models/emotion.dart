import 'package:cloud_firestore/cloud_firestore.dart';

class Emotion {
  final String id;
  final int order;
  final String emoji;
  final String name;
  final String description;
  final double coefficient;

  Emotion({
    required this.id,
    required this.order,
    required this.emoji,
    required this.name,
    required this.description,
    required this.coefficient,
  });

  factory Emotion.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Emotion(
      id: doc.id,
      order: data['order'] ?? 0,
      emoji: data['emoji'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      coefficient: (data['coefficient'] != null)
          ? (data['coefficient'] as num).toDouble()
          : 0.0001,
    );
  }

  factory Emotion.fromMap(Map<String, dynamic> data, {required String id}) {
    return Emotion(
      id: id,
      order: data['order'] ?? 0,
      emoji: data['emoji'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      coefficient: (data['coefficient'] != null)
          ? (data['coefficient'] as num).toDouble()
          : 0.0001,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order': order,
      'emoji': emoji,
      'name': name,
      'description': description,
      'coefficient': coefficient,
    };
  }
}
