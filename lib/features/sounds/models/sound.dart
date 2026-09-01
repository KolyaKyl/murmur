import 'package:cloud_firestore/cloud_firestore.dart';

class Sound {
  const Sound({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categories,
    required this.audioPath,
    required this.coverPath,
    required this.durationSec,
    required this.premium,
    required this.order,
    required this.bundled,
    required this.assetPath,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Список, а не одно значение: звук попадает под несколько фильтров сразу.
  final List<String> categories;

  /// Путь внутри бакета, не готовая ссылка — файл можно перезалить,
  /// и в базе ничего менять не надо.
  final String audioPath;
  final String coverPath;

  final int durationSec;
  final bool premium;
  final int order;

  /// Файл лежит внутри приложения — играет без сети и не тратит трафик.
  final bool bundled;
  final String assetPath;

  factory Sound.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Sound(
      id: doc.id,
      title: d['title'] as String? ?? '',
      subtitle: d['subtitle'] as String? ?? '',
      categories: (d['categories'] as List?)?.cast<String>() ?? const [],
      audioPath: d['audioPath'] as String? ?? '',
      coverPath: d['coverPath'] as String? ?? '',
      durationSec: (d['durationSec'] as num?)?.toInt() ?? 0,
      premium: d['premium'] as bool? ?? false,
      order: (d['order'] as num?)?.toInt() ?? 0,
      bundled: d['bundled'] as bool? ?? false,
      assetPath: d['assetPath'] as String? ?? '',
    );
  }
}

/// Сохранённый микс: состав и громкости.
class SavedMix {
  const SavedMix({
    required this.id,
    required this.name,
    required this.soundIds,
    required this.volumes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> soundIds;
  final Map<String, double> volumes;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'name': name,
        'soundIds': soundIds,
        'volumes': volumes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SavedMix.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SavedMix(
      id: doc.id,
      name: d['name'] as String? ?? '',
      soundIds: (d['soundIds'] as List?)?.cast<String>() ?? const [],
      volumes: ((d['volumes'] as Map?) ?? {}).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
