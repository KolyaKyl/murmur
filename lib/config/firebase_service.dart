import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:self_screen/models/app_user.dart';
import 'package:self_screen/models/emotion.dart';
import 'package:self_screen/models/mood_record.dart';
import 'package:self_screen/models/psychological_test.dart';
import 'package:self_screen/models/question_answer.dart';
import 'package:self_screen/models/test_result.dart';
import 'package:self_screen/widgets/analysis/wellness_index.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Emotion>> fetchEmotions() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('emotions').orderBy('order').get();

      final emotions = snapshot.docs.map((doc) {
        return Emotion.fromDoc(doc);
      }).toList();

      return emotions;
    } catch (e) {
      // print('Error fetching emotions: $e');
      return [];
    }
  }

//mood records
  Future<void> saveMoodRecord({
    required String userId,
    required Emotion emotion,
    required num level,
    required List<String> selectedTriggers,
    required List<String> userTriggers,
    required String? note,
    required GlobalKey<WellnessCardState> wellnessCardKey,
    required String recordId,
    required DateTime dateTime,
  }) async {
    final direction = (emotion.coefficient - 0.5) * 2; // от -0.8 до +1.0
    final normalizedLevel = level / 10; // от 0.1 до 1.0
    final moodIndex = direction * normalizedLevel; // от -0.8 до +1.0

    final moodData = {
      'userId': userId,
      'timestamp': Timestamp.fromDate(dateTime),
      'name': emotion.name,
      'emoji': emotion.emoji,
      'coefficient': emotion.coefficient,
      'level': level,
      'moodIndex': moodIndex,
      'selectedTriggers': selectedTriggers,
      'note': note != null && note.trim().isNotEmpty ? note.trim() : '',
      'edited': recordId.isEmpty ? false : true,
    };

    // Запись настроения
    final moodCollection =
        _firestore.collection('users').doc(userId).collection('MoodRecords');

    if (recordId.isNotEmpty) {
      final moodRecDoc = moodCollection.doc(recordId);

      try {
        await moodRecDoc.set(moodData, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving user: $e');
        await moodCollection.add(moodData);
        rethrow;
      }
    } else {
      await moodCollection.add(moodData);
    }

    // Обновление всех триггеров пользователя
    final userDocRef = _firestore.collection('users').doc(userId);
    await userDocRef.set({
      'triggers': userTriggers,
    }, SetOptions(merge: true));

    final newIndex = await calculate7DayWellnessIndex(userId);
    wellnessCardKey.currentState?.updateWellnessIndex(newIndex);
  }

  Future<bool> deleteMoodRecord(
    String userId,
    String recordId,
    GlobalKey<WellnessCardState> wellnessCardKey,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('MoodRecords')
          .doc(recordId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
          return true;
        }
      });
      final newIndex = await calculate7DayWellnessIndex(userId);
      wellnessCardKey.currentState?.updateWellnessIndex(newIndex);
      return true;
    } catch (e) {
      ('Error deleting mood rec: $e');
      return false;
    }
  }

  Future<List<MoodRecord>> fetchMoodRecords(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('MoodRecords')
          .orderBy('timestamp', descending: true)
          .get();

      final moodRecords = snapshot.docs.map((doc) {
        return MoodRecord.fromDoc(doc);
      }).toList();

      return moodRecords;
    } catch (e) {
      e.toString();
      return [];
    }
  }

//wellness card
  Future<int> calculate7DayWellnessIndex(String userId) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('MoodRecords')
        .where('timestamp', isGreaterThanOrEqualTo: sevenDaysAgo)
        .get();

    final moodValues = querySnapshot.docs
        .map((doc) => doc['moodIndex'] as num?)
        .where((val) => val != null)
        .map((val) => val!.toDouble())
        .toList();

    return computeDayIndex(moodValues);
  }

  int computeDayIndex(List<double> moodValues) {
    if (moodValues.isEmpty) return 0;
    final avg = moodValues.reduce((a, b) => a + b) / moodValues.length;
    final index = ((avg + 1) / 2) * 100;
    return index.round().clamp(0, 100);
  }

//users
  Future<void> saveUser({
    required String id,
    required String name,
    required String email,
    String gender = 'unknown',
    DateTime? birthDate,
    String photoUrl = '',
    bool isDarkTheme = false,
  }) async {
    final userDoc = _firestore.collection('users').doc(id);

    final userData = {
      'name': name,
      'email': email,
      'triggers': <String>[],
      'gender': gender,
      'birthDate': Timestamp.fromDate(birthDate ?? DateTime(1990, 1, 1)),
      'photoUrl': photoUrl,
      'isDarkTheme': isDarkTheme,
    };

    try {
      await userDoc.set(userData, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Получение данных пользователя
  Future<AppUser?> getAppUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromDoc(doc);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadUserProfilePhoto(File file, String userId) async {
    try {
      final fileName = 'avatar_$userId';
      final ref =
          FirebaseStorage.instance.ref().child('users/$userId/$fileName.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return '';
    }
  }

  // Обновление профиля (name, gender, birthDate и т.д.)
  Future<void> updateUserProfile(AppUser user) async {
    final userDoc = _firestore.collection('users').doc(user.id);
    try {
      await userDoc.update(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Отдельное обновление темы
  Future<void> updateUserThemePreference(bool isDark) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isDarkTheme': isDark,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Удаляем документ пользователя и две подколлекции
  Future<void> deleteUserData(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);

    // 1. Удаляем из Storage: все файлы в каталоге profile_photos
    final photosRef = _storage.ref().child('users/$userId');
    try {
      final listResult = await photosRef.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // если папки нет или ещё какие-то ошибки — проигнорируем
      debugPrint('Error deleting profile photos: $e');
    }

    // 2. Удаляем TestResults
    final testResultsCol = userDoc.collection('TestsResults');
    final testResultsSnap = await testResultsCol.get();
    for (final doc in testResultsSnap.docs) {
      await doc.reference.delete();
    }

    // 3. Удаляем MoodRecords
    final moodRecordsCol = userDoc.collection('MoodRecords');
    final moodRecordsSnap = await moodRecordsCol.get();
    for (final doc in moodRecordsSnap.docs) {
      await doc.reference.delete();
    }

    // 4. Удаляем документ пользователя
    await userDoc.delete();
  }

// tests
  Future<List<Question>> fetchTestQuestions(String testId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tests')
          .doc(testId)
          .collection('Questions')
          .orderBy('Order')
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching test questions: $e');
      return [];
    }
  }

//admin tool
  Future<void> saveTestResult({
    required String userId,
    required PsychologicalTest test,
    required int score,
  }) async {
    int maxLevel = getMaxLevel(test.levels);
    final resultMap = getRecommendation(score, test.levels);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('TestsResults')
          .add({
        'testId': test.id,
        'title': test.title,
        'subname': test.subname,
        'helper': test.helper,
        'score': score,
        'result': resultMap['result'],
        'recommendation': resultMap['recommendation'],
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'maxLevel': maxLevel - 1,
      });
    } catch (e) {
      debugPrint('Error saving test result: $e');
      rethrow;
    }
  }

  int getMaxLevel(List<Map<String, dynamic>> levels) {
    return levels
        .map((level) => level['max'] ?? 0)
        .fold<int>(0, (prev, max) => max > prev ? max : prev);
  }

  Map<String, String> getRecommendation(
      int score, List<Map<String, dynamic>> levels) {
    for (final level in levels) {
      final int min = level['min'] ?? 0;
      final int max = level['max'] ?? 0;
      final String recommendation = level['recommendation'] ?? '';
      final String result = level['result'] ?? '';

      if (score >= min && score < max) {
        return {
          'result': result,
          'recommendation': recommendation,
        };
      }
    }
    return {
      'result': 'Unknown',
      'recommendation': 'Score is out of range.',
    };
  }

  Future<Map<String, TestResult>> fetchLatestUserTestResults(
    String userId,
    List<PsychologicalTest> tests,
  ) async {
    // final firestore = FirebaseFirestore.instance;

    // Получаем результаты пользователя, отсортированные по времени
    final resultsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('TestsResults')
        .orderBy('timestamp', descending: true)
        .get();

    final results = resultsSnapshot.docs;

    // Преобразуем в Map<testId, TestResult>, оставляя только последний результат для каждого теста
    final Map<String, TestResult> latestResultsByTestId = {};

    for (var resultDoc in results) {
      final data = resultDoc.data();
      final testId = data['testId'];
      if (testId != null && !latestResultsByTestId.containsKey(testId)) {
        latestResultsByTestId[testId] = TestResult.fromMap(resultDoc.id, data);
      }
    }

    return latestResultsByTestId;
  }

  Future<List<TestResult>> fetchUserTestResults(
      String userId, String testId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('TestsResults')
        .where('testId', isEqualTo: testId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => TestResult.fromMap(doc.id, doc.data()))
        .toList();
  }

//google analytics
  static void logEvent(String name) {
    FirebaseAnalytics.instance.logEvent(
      name: name,
    );
  }
}
