import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/vc/auth_providers.dart';
import '../model/profile_api.dart';

class ProfilePostsState {
  final bool loading;
  final bool loadingMore;
  final String? error;

  final List<Map<String, dynamic>> posts;
  final int page;
  final bool hasMore;

  const ProfilePostsState({
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.posts = const [],
    this.page = 1,
    this.hasMore = true,
  });

  ProfilePostsState copyWith({
    bool? loading,
    bool? loadingMore,
    String? error,
    List<Map<String, dynamic>>? posts,
    int? page,
    bool? hasMore,
  }) {
    return ProfilePostsState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      posts: posts ?? this.posts,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ProfilePostsVC extends Notifier<ProfilePostsState> {
  @override
  ProfilePostsState build() => const ProfilePostsState();

  ProfileApi get _api => ProfileApi(ref.read(apiClientProvider));

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
        final msg = (data['message'] ?? '').toString();
        if (msg.trim().isNotEmpty) return msg;
      }
      if (status == 401)
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      if (status != null && status >= 500)
        return 'Hệ thống đang bận. Vui lòng thử lại sau.';
      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  Map<String, dynamic> _getPostsPaginator(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is! Map) throw Exception('Response không hợp lệ (data).');

    final posts = data['posts'];
    if (posts is! Map) throw Exception('Response không hợp lệ (data.posts).');

    return Map<String, dynamic>.from(posts);
  }

  List<Map<String, dynamic>> _parseList(Map<String, dynamic> paginator) {
    final list = (paginator['data'] as List? ?? const []);
    return List<Map<String, dynamic>>.from(
      list.map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  int _int(dynamic v, int fallback) => (v is num) ? v.toInt() : fallback;

  Future<void> load({int perPage = 30}) async {
    state = state.copyWith(
      loading: true,
      error: null,
      posts: const [],
      page: 1,
      hasMore: true,
    );

    try {
      final res = await _api.fetchMyPosts(page: 1, perPage: perPage);
      final paginator = _getPostsPaginator(res);

      final currentPage = _int(paginator['current_page'], 1);
      final lastPage = _int(paginator['last_page'], 1);

      state = state.copyWith(
        loading: false,
        posts: _parseList(paginator),
        page: currentPage,
        hasMore: currentPage < lastPage,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _friendly(e as Object));
    }
  }

  Future<void> loadMore({int perPage = 30}) async {
    if (state.loading || state.loadingMore || !state.hasMore) return;

    state = state.copyWith(loadingMore: true, error: null);

    try {
      final nextPage = state.page + 1;
      final res = await _api.fetchMyPosts(page: nextPage, perPage: perPage);
      final paginator = _getPostsPaginator(res);

      final currentPage = _int(paginator['current_page'], nextPage);
      final lastPage = _int(paginator['last_page'], currentPage);

      final merged = [...state.posts, ..._parseList(paginator)];

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

  void clearError() => state = state.copyWith(error: null);
}

final profilePostsVCProvider =
    NotifierProvider<ProfilePostsVC, ProfilePostsState>(ProfilePostsVC.new);
