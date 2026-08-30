import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:murmur/core/models/app_user.dart';
import 'package:murmur/features/mood/models/emotion.dart';
import 'package:murmur/features/mood/models/mood_record.dart';

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
      debugPrint('fetchEmotions failed: $e');
      rethrow;
    }
  }

//mood records
  /// Возвращает пересчитанный индекс за 7 дней — вызывающий кладёт его
  /// в moodIndexProvider.
  Future<int> saveMoodRecord({
    required String userId,
    required Emotion emotion,
    required num level,
    required List<String> selectedTriggers,
    required List<String> userTriggers,
    required String? note,
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
      // Раньше при ошибке set здесь делался add — и в базе оставалась
      // вторая копия записи, которую никто не удалял. Теперь просто
      // отдаём ошибку наверх, вызывающий показывает её пользователю.
      await moodCollection.doc(recordId).set(moodData, SetOptions(merge: true));
    } else {
      await moodCollection.add(moodData);
    }

    // Обновление всех триггеров пользователя
    final userDocRef = _firestore.collection('users').doc(userId);
    await userDocRef.set({
      'triggers': userTriggers,
    }, SetOptions(merge: true));

    return calculate7DayWellnessIndex(userId);
  }

  /// null — удалить не удалось. Иначе пересчитанный индекс за 7 дней.
  Future<int?> deleteMoodRecord(
    String userId,
    String recordId,
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
      return await calculate7DayWellnessIndex(userId);
    } catch (e) {
      debugPrint('deleteMoodRecord failed: $e');
      return null;
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
      debugPrint('fetchMoodRecords failed: $e');
      rethrow;
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

    await userDoc.set(userData, SetOptions(merge: true));
  }

  // Получение данных пользователя
  Future<AppUser?> getAppUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      // null здесь означает только «документа ещё нет» — это штатный случай
      // для только что зарегистрированного пользователя. Ошибки летят наверх.
      return doc.exists ? AppUser.fromDoc(doc) : null;
    } catch (e) {
      debugPrint('getAppUserData failed: $e');
      rethrow;
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
      debugPrint('uploadUserProfilePhoto failed: $e');
      return null;
    }
  }

  // Обновление профиля (name, gender, birthDate и т.д.)
  Future<void> updateUserProfile(AppUser user) async {
    final userDoc = _firestore.collection('users').doc(user.id);
    await userDoc.update(user.toMap());
  }

  // Отдельное обновление темы
  Future<void> updateUserThemePreference(bool isDark) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isDarkTheme': isDark,
    });
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

    // 2. Удаляем MoodRecords
    final moodRecordsCol = userDoc.collection('MoodRecords');
    final moodRecordsSnap = await moodRecordsCol.get();
    for (final doc in moodRecordsSnap.docs) {
      await doc.reference.delete();
    }

    // 3. Удаляем документ пользователя
    await userDoc.delete();
  }

//google analytics
  static void logEvent(String name) {
    FirebaseAnalytics.instance.logEvent(
      name: name,
    );
  }
}
