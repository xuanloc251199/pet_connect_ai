enum KnowledgePetType { all, dog, cat, both }

class KnowledgeArticle {
  final int id;
  final KnowledgePetType pet;

  final String title;
  final String summary;

  final List<String> symptoms;
  final List<String> causes;
  final int dangerLevel; // 1..5
  final List<String> firstAid;
  final List<String> tags;

  KnowledgeArticle({
    required this.id,
    required this.pet,
    required this.title,
    required this.summary,
    required this.symptoms,
    required this.causes,
    required this.dangerLevel,
    required this.firstAid,
    required this.tags,
  });

  /// Parse tolerant: hỗ trợ nhiều key khác nhau để không phụ thuộc backend cứng
  factory KnowledgeArticle.fromApi(Map<String, dynamic> json) {
    final id = _asInt(json['id']) ?? 0;

    final petRaw = (json['pet'] ?? json['pet_type'] ?? json['species'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final pet = _petFromString(petRaw);

    final title = (json['title'] ?? json['name'] ?? '').toString();
    final summary = (json['summary'] ?? json['description'] ?? '').toString();

    final symptoms = _asStringList(json['symptoms'] ?? json['symptom']);
    final causes = _asStringList(json['causes'] ?? json['cause']);
    final firstAid = _asStringList(json['first_aid'] ?? json['firstAid']);
    final tags = _asStringList(json['tags'] ?? json['keywords']);

    final danger = (_asInt(json['danger_level'] ?? json['dangerLevel']) ?? 3)
        .clamp(1, 5);

    return KnowledgeArticle(
      id: id,
      pet: pet,
      title: title,
      summary: summary,
      symptoms: symptoms,
      causes: causes,
      dangerLevel: danger,
      firstAid: firstAid,
      tags: tags,
    );
  }

  static int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v');

  static List<String> _asStringList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return const [];
      // cho phép backend trả "a;b;c" hoặc "a, b, c"
      final parts = s.contains(';') ? s.split(';') : s.split(',');
      return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static KnowledgePetType _petFromString(String s) {
    if (s == 'dog' || s == 'cho') return KnowledgePetType.dog;
    if (s == 'cat' || s == 'meo') return KnowledgePetType.cat;
    if (s == 'both' || s == 'dog_cat' || s == 'cho_meo') {
      return KnowledgePetType.both;
    }
    return KnowledgePetType.all;
  }
}
