import '../../../app/core/api_client.dart';

class KnowledgeApi {
  final ApiClient client;
  KnowledgeApi(this.client);

  Future<dynamic> fetchArticles({
    int page = 1,
    int perPage = 20,
    String? q,
    String? pet, // 'dog'|'cat'|'both' or null
  }) async {
    final res = await client.dio.get(
      '/knowledge',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (pet != null && pet.trim().isNotEmpty) 'pet': pet.trim(),
      },
    );
    return res.data;
  }
}
