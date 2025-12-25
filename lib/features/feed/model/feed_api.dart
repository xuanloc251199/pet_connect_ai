import 'package:dio/dio.dart';
import '../../../app/core/api_client.dart';

class FeedApi {
  final Dio _dio;
  FeedApi(ApiClient client) : _dio = client.dio;

  /// GET /feed (auth)
  Future<Map<String, dynamic>> fetchFeed({
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await _dio.get(
      'feed',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// POST /posts/{id}/like
  Future<Map<String, dynamic>> toggleLike(int postId) async {
    final res = await _dio.post('posts/$postId/like');
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// GET /posts/{id}/comments
  Future<Map<String, dynamic>> fetchComments({
    required int postId,
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _dio.get(
      'posts/$postId/comments',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// POST /posts/{id}/comments
  Future<Map<String, dynamic>> addComment({
    required int postId,
    required String content,
  }) async {
    final res = await _dio.post(
      'posts/$postId/comments',
      data: {'content': content},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// DELETE /comments/{id}
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    final res = await _dio.delete('comments/$commentId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> fetchPostDetail(int postId) async {
    final res = await _dio.get('posts/$postId');
    return Map<String, dynamic>.from(res.data as Map);
  }
}
