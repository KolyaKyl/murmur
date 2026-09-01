import 'package:cloud_firestore/cloud_firestore.dart';

/// Категория справочника: и у звуков, и у практик она устроена одинаково.
/// Живёт в Firestore, поэтому новая категория добавляется документом —
/// без правки кода и без выпуска новой версии приложения.
///
/// Названия английские, как и весь остальной текст из базы.
class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.title,
    required this.order,
  });

  final String id;
  final String title;
  final int order;

  factory CatalogCategory.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CatalogCategory(
      id: doc.id,
      title: d['title'] as String? ?? doc.id,
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }
}
