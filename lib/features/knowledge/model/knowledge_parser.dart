import 'knowledge_article.dart';

class KnowledgeParser {
  static List<KnowledgeArticle> parseFromResponse(dynamic resData) {
    final root = (resData is Map) ? resData : <String, dynamic>{};
    final data = root['data'];

    List<dynamic> list;
    if (data is Map && data['data'] is List) {
      // paginate: data.data
      list = data['data'] as List;
    } else if (data is Map && data['items'] is List) {
      // alt: data.items
      list = data['items'] as List;
    } else if (data is List) {
      list = data;
    } else {
      list = const [];
    }

    return list
        .whereType<Map>()
        .map(
          (e) => KnowledgeArticle.fromApi(Map<String, dynamic>.from(e as Map)),
        )
        .where((a) => a.id > 0 && a.title.trim().isNotEmpty)
        .toList();
  }
}
