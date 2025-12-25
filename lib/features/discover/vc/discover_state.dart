import '../model/discover_tile.dart';

class DiscoverState {
  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<DiscoverTile> items;
  final int page;
  final bool hasMore;
  final String query;

  const DiscoverState({
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.query = '',
  });

  DiscoverState copyWith({
    bool? loading,
    bool? loadingMore,
    String? error,
    List<DiscoverTile>? items,
    int? page,
    bool? hasMore,
    String? query,
  }) {
    return DiscoverState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
    );
  }
}
