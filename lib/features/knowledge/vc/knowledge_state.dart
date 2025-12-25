import '../model/knowledge_article.dart';

class KnowledgeState {
  final bool loading;
  final bool loadingMore;
  final String? error;

  final List<KnowledgeArticle> items;

  final int page;
  final bool hasMore;

  final String query;
  final KnowledgePetType pet;

  const KnowledgeState({
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.query = '',
    this.pet = KnowledgePetType.all,
  });

  KnowledgeState copyWith({
    bool? loading,
    bool? loadingMore,
    String? error,
    List<KnowledgeArticle>? items,
    int? page,
    bool? hasMore,
    String? query,
    KnowledgePetType? pet,
  }) {
    return KnowledgeState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      pet: pet ?? this.pet,
    );
  }
}
