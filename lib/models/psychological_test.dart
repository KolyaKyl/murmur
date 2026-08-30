class PsychologicalTest {
  final String id;
  final String title;
  final String subname;
  final String description;
  final String helper;
  final String source;
  final String sourceFull;
  final String logoUrl;
  final List<Map<String, dynamic>> levels;

  PsychologicalTest({
    required this.id,
    required this.title,
    required this.subname,
    required this.description,
    required this.helper,
    required this.source,
    required this.sourceFull,
    required this.logoUrl,
    required this.levels,
  });

  factory PsychologicalTest.fromMap(String id, Map<String, dynamic> data) {
    return PsychologicalTest(
      id: id,
      title: data['title'] ?? '',
      subname: data['subname'] ?? '',
      description: data['description'] ?? '',
      helper: data['helper'] ?? '',
      source: data['source'] ?? '',
      sourceFull: data['sourceFull'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      levels: (data['levels'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
  }
}
