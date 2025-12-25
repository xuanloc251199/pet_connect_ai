class InterestItem {
  final int id;
  final String name;

  const InterestItem({required this.id, required this.name});

  factory InterestItem.fromJson(Map<String, dynamic> json) => InterestItem(
    id: (json['id'] as num).toInt(),
    name: (json['name'] ?? '') as String,
  );
}

class InterestCategory {
  final int id;
  final String name;
  final List<InterestItem> interests;

  const InterestCategory({
    required this.id,
    required this.name,
    required this.interests,
  });

  factory InterestCategory.fromJson(Map<String, dynamic> json) =>
      InterestCategory(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        interests: ((json['interests'] ?? []) as List)
            .map((e) => InterestItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
