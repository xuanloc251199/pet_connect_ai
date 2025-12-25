import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/vc/auth_providers.dart';
import '../model/feed_api.dart';
import '../model/feed_models.dart';

class FeedState {
  final bool loading;
  final bool loadingMore;
  final String? error;

  final List<FeedPost> posts;
  final int page;
  final bool hasMore;

  const FeedState({
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.posts = const [],
    this.page = 1,
    this.hasMore = true,
  });

  FeedState copyWith({
    bool? loading,
    bool? loadingMore,
    String? error,
    List<FeedPost>? posts,
    int? page,
    bool? hasMore,
  }) {
    return FeedState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      posts: posts ?? this.posts,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FeedVC extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedState();

  FeedApi get _api => FeedApi(ref.read(apiClientProvider));

  String _friendly(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối mạng. Vui lòng kiểm tra Wi-Fi/4G.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Kết nối quá lâu. Thử lại nhé.';
      }
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (data is Map) {
        final msg = (data['message'] ?? '').toString().trim();
        if (msg.isNotEmpty) return msg;
      }
      if (status == 401)
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      if (status != null && status >= 500)
        return 'Hệ thống đang bận. Vui lòng thử lại sau.';
      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  Map<String, dynamic> _extractPaginator(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map && data['posts'] is Map) {
      return Map<String, dynamic>.from(data['posts'] as Map);
    }
    if (data is Map && data['data'] is List) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Response feed không hợp lệ.');
  }

  int _int(dynamic v, int fallback) => (v is num) ? v.toInt() : fallback;

  List<FeedPost> _parsePosts(Map<String, dynamic> paginator) {
    final list = (paginator['data'] as List? ?? const []);
    return list
        .map((e) => FeedPost.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> load({int perPage = 10}) async {
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      error: null,
      posts: const [],
      page: 1,
      hasMore: true,
    );

    try {
      final res = await _api.fetchFeed(page: 1, perPage: perPage);
      final paginator = _extractPaginator(res);

      final currentPage = _int(paginator['current_page'], 1);
      final lastPage = _int(paginator['last_page'], 1);

      state = state.copyWith(
        loading: false,
        posts: _parsePosts(paginator),
        page: currentPage,
        hasMore: currentPage < lastPage,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _friendly(e as Object));
    }
  }

  Future<void> loadMore({int perPage = 10}) async {
    if (state.loading || state.loadingMore || !state.hasMore) return;

    state = state.copyWith(loadingMore: true, error: null);

    try {
      final nextPage = state.page + 1;
      final res = await _api.fetchFeed(page: nextPage, perPage: perPage);
      final paginator = _extractPaginator(res);

      final currentPage = _int(paginator['current_page'], nextPage);
      final lastPage = _int(paginator['last_page'], currentPage);

      final merged = [...state.posts, ..._parsePosts(paginator)];

      state = state.copyWith(
        loadingMore: false,
        posts: merged,
        page: currentPage,
        hasMore: currentPage < lastPage,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: _friendly(e as Object));
    }
  }

  void prependPost(FeedPost post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  Future<void> toggleLike(int postId) async {
    final idx = state.posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;

    final old = state.posts[idx];

    // optimistic
    final optimistic = old.copyWith(
      isLiked: !old.isLiked,
      likes: old.isLiked ? (old.likes - 1).clamp(0, 1 << 30) : old.likes + 1,
    );

    final next = [...state.posts];
    next[idx] = optimistic;
    state = state.copyWith(posts: next, error: null);

    try {
      final res = await _api.toggleLike(postId);
      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};

      final liked =
          (data['liked'] == true) ||
          (data['liked'] == 1) ||
          (data['liked'] == '1');
      final likesCount =
          (data['likes_count'] as num?)?.toInt() ?? optimistic.likes;

      final fixed = optimistic.copyWith(isLiked: liked, likes: likesCount);

      final after = [...state.posts];
      final idx2 = after.indexWhere((p) => p.id == postId);
      if (idx2 >= 0) {
        after[idx2] = fixed;
        state = state.copyWith(posts: after);
      }
    } catch (e) {
      final rollback = [...state.posts];
      final idx2 = rollback.indexWhere((p) => p.id == postId);
      if (idx2 >= 0) rollback[idx2] = old;
      state = state.copyWith(posts: rollback, error: _friendly(e as Object));
    }
  }

  void updateCommentsCount(int postId, int commentsCount) {
    final idx = state.posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;

    final old = state.posts[idx];
    final next = [...state.posts];
    next[idx] = old.copyWith(comments: commentsCount);
    state = state.copyWith(posts: next);
  }

  Future<void> refresh({int perPage = 10}) async {
    await load(perPage: perPage);
  }

  void prependLocal(FeedPost post) {
    final exists = state.posts.any((p) => p.id == post.id);
    if (exists) return;
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  void clearError() => state = state.copyWith(error: null);
}

final feedVCProvider = NotifierProvider<FeedVC, FeedState>(FeedVC.new);
