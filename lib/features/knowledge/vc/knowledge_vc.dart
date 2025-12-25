import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/vc/auth_providers.dart';
import '../model/knowledge_api.dart';
import '../model/knowledge_parser.dart';
import '../model/knowledge_article.dart';
import 'knowledge_state.dart';

final knowledgeApiProvider = Provider<KnowledgeApi>((ref) {
  final client = ref.read(apiClientProvider);
  return KnowledgeApi(client);
});

final knowledgeVCProvider = NotifierProvider<KnowledgeVC, KnowledgeState>(
  KnowledgeVC.new,
);

class KnowledgeVC extends Notifier<KnowledgeState> {
  static const int _perPage = 20;

  @override
  KnowledgeState build() => const KnowledgeState();

  Future<void> refresh({String? query, KnowledgePetType? pet}) async {
    final q = (query ?? state.query).trim();
    final p = pet ?? state.pet;

    state = state.copyWith(
      loading: true,
      error: null,
      page: 1,
      hasMore: true,
      query: q,
      pet: p,
    );

    try {
      final api = ref.read(knowledgeApiProvider);
      final raw = await api.fetchArticles(
        page: 1,
        perPage: _perPage,
        q: q,
        pet: _petParam(p),
      );

      final items = KnowledgeParser.parseFromResponse(raw);
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
      final api = ref.read(knowledgeApiProvider);
      final raw = await api.fetchArticles(
        page: nextPage,
        perPage: _perPage,
        q: state.query,
        pet: _petParam(state.pet),
      );

      final newItems = KnowledgeParser.parseFromResponse(raw);

      final seen = state.items.map((e) => e.id).toSet();
      final merged = [
        ...state.items,
        ...newItems.where((e) => !seen.contains(e.id)),
      ];

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
    if (raw is Map && raw['data'] is Map) {
      final data = raw['data'] as Map;
      final current = (data['current_page'] as num?)?.toInt();
      final last = (data['last_page'] as num?)?.toInt();
      if (current != null && last != null) return current < last;
      // alt style: next_page_url
      final nextUrl = data['next_page_url'];
      if (nextUrl is String) return nextUrl.trim().isNotEmpty;
    }
    return fetchedCount >= 1;
  }

  String? _petParam(KnowledgePetType p) {
    switch (p) {
      case KnowledgePetType.dog:
        return 'dog';
      case KnowledgePetType.cat:
        return 'cat';
      case KnowledgePetType.both:
        return 'both';
      case KnowledgePetType.all:
        return null;
    }
  }
}
