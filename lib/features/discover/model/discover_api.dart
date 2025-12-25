import '../../../app/core/api_client.dart';

class DiscoverApi {
  final ApiClient client;
  DiscoverApi(this.client);

  Future<dynamic> fetchFeed({int page = 1, String? q}) async {
    final res = await client.dio.get(
      '/discover',
      queryParameters: {
        'page': page,
        if (q != null && q.trim().isNotEmpty)
          'q': q.trim(), // nếu backend hỗ trợ search
      },
    );
    return res.data;
  }
}
