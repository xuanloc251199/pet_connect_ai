import '../../../app/core/api_client.dart';
import 'post_item.dart';

class PostsApi {
  final ApiClient client;
  PostsApi(this.client);

  Future<PostItem> getPostDetail(int postId) async {
    final res = await client.dio.get('/posts/$postId');
    if (res.data is Map && res.data['success'] == true) {
      final data = (res.data['data'] as Map).cast<String, dynamic>();
      return PostItem.fromJson(data);
    }
    throw Exception(res.data?['message'] ?? 'Load post failed');
  }
}
