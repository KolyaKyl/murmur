import 'package:cloud_firestore/cloud_firestore.dart';

class TestResult {
  final String id;
  final String testId;
  final String title;
  final String subname;
  final String result;
  final String recommendation;
  final DateTime timestamp;
  final int score;
  final int maxLevel;

  TestResult({
    required this.id,
    required this.testId,
    required this.title,
    required this.subname,
    required this.result,
    required this.recommendation,
    required this.timestamp,
    required this.score,
    required this.maxLevel,
  });

  factory TestResult.fromMap(String id, Map<String, dynamic> data) {
    return TestResult(
      id: id,
      testId: data['testId'] ?? '',
      title: data['title'] ?? '',
      subname: data['subname'] ?? '',
      result: data['result'] ?? '',
      recommendation: data['recommendation'] ?? '',
      timestamp: (data['timestamp'] != null && data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      score: data['score'] ?? 0,
      maxLevel: data['maxLevel'] ?? 0,
    );
  }
}
