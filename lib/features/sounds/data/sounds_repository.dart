import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:murmur/features/sounds/models/sound.dart';
import 'package:murmur/core/models/catalog_category.dart';

/// Каталог и пользовательские списки. Ошибки не глотает — экран сам
/// решает, что показать.
class SoundsRepository {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  static final Map<String, String> _urlCache = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _userCol(String name) {
    final uid = _uid;
    return uid == null
        ? null
        : _db.collection('users').doc(uid).collection(name);
  }

  Future<List<Sound>> fetchSounds() async {
    final snap = await _db.collection('sounds').orderBy('order').get();
    return snap.docs.map(Sound.fromDoc).toList();
  }

  Future<List<CatalogCategory>> fetchCategories() async {
    final snap = await _db.collection('soundCategories').orderBy('order').get();
    return snap.docs.map(CatalogCategory.fromDoc).toList();
  }

  /// Ссылку на файл спрашиваем у Storage один раз за сессию — она стоит
  /// сетевого запроса, а меняется только при перезаливке.
  Future<String> resolveUrl(String path) async {
    final cached = _urlCache[path];
    if (cached != null) return cached;
    final url = await _storage.ref(path).getDownloadURL();
    _urlCache[path] = url;
    return url;
  }

  // --- избранное ---

  Future<Set<String>> fetchFavoriteIds() async {
    final col = _userCol('favorites');
    if (col == null) return {};
    final snap = await col.get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<void> setFavorite(String soundId, bool value) async {
    final col = _userCol('favorites');
    if (col == null) return;
    if (value) {
      await col.doc(soundId).set({'addedAt': FieldValue.serverTimestamp()});
    } else {
      await col.doc(soundId).delete();
    }
  }

  // --- миксы ---

  Future<List<SavedMix>> fetchMixes() async {
    final col = _userCol('mixes');
    if (col == null) return [];
    final snap = await col.orderBy('createdAt', descending: true).get();
    return snap.docs.map(SavedMix.fromDoc).toList();
  }

  Future<void> saveMix(SavedMix mix) async {
    final col = _userCol('mixes');
    if (col == null) return;
    await col.doc(mix.id).set(mix.toMap());
  }

  Future<void> deleteMix(String id) async {
    await _userCol('mixes')?.doc(id).delete();
  }

  // --- недавние ---

  static const recentLimit = 15;

  Future<List<String>> fetchRecentIds() async {
    final col = _userCol('recent');
    if (col == null) return [];
    final snap = await col
        .orderBy('playedAt', descending: true)
        .limit(recentLimit)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// Список подрезаем здесь же: иначе он растёт бесконечно, а нужны последние 15.
  Future<void> pushRecent(String soundId) async {
    final col = _userCol('recent');
    if (col == null) return;
    try {
      await col.doc(soundId).set({'playedAt': FieldValue.serverTimestamp()});
      final snap = await col.orderBy('playedAt', descending: true).get();
      for (final doc in snap.docs.skip(recentLimit)) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('pushRecent failed: $e');
    }
  }
}
