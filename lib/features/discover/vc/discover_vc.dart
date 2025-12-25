import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/vc/auth_providers.dart';
import '../model/discover_api.dart';
import '../model/discover_parser.dart';
import 'discover_state.dart';

final discoverApiProvider = Provider<DiscoverApi>((ref) {
  final client = ref.read(apiClientProvider);
  return DiscoverApi(client);
});

final discoverVCProvider = NotifierProvider<DiscoverVC, DiscoverState>(
  DiscoverVC.new,
);

class DiscoverVC extends Notifier<DiscoverState> {
  @override
  DiscoverState build() => const DiscoverState();

  Future<void> refresh({String? query}) async {
    final q = (query ?? state.query).trim();
    state = state.copyWith(
      loading: true,
      error: null,
      page: 1,
      hasMore: true,
      query: q,
    );

    try {
      final api = ref.read(discoverApiProvider);
      final raw = await api.fetchFeed(page: 1, q: q);
      final items = DiscoverParser.parseFromFeedResponse(raw);

      final hasMore = _inferHasMore(raw, items.length);

      state = state.copyWith(
        loading: false,
        items: items,
        page: 1,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(loadingMore: true, error: null);

    try {
      final api = ref.read(discoverApiProvider);
      final raw = await api.fetchFeed(page: nextPage, q: state.query);
      final newItems = DiscoverParser.parseFromFeedResponse(raw);

      final merged = [...state.items, ...newItems];
      final hasMore = _inferHasMore(raw, newItems.length);

      state = state.copyWith(
        loadingMore: false,
        items: merged,
        page: nextPage,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  bool _inferHasMore(dynamic raw, int fetchedCount) {
    // paginate hint
    if (raw is Map && raw['data'] is Map) {
      final data = raw['data'] as Map;
      final current = (data['current_page'] as num?)?.toInt();
      final last = (data['last_page'] as num?)?.toInt();
      if (current != null && last != null) return current < last;
    }
    return fetchedCount > 0;
  }
}
