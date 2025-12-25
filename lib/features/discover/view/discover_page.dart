import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../feed/view/post_detail_page.dart';
import '../../posts/view/post_detail_page.dart';
import '../vc/discover_vc.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() => ref.read(discoverVCProvider.notifier).refresh());

    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
        ref.read(discoverVCProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(discoverVCProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(discoverVCProvider.notifier).refresh(query: st.query),
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(child: _topSearch(st.query)),
          if (st.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (st.error != null && st.items.isEmpty)
            SliverFillRemaining(child: _errorEmpty(st.error!))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              sliver: SliverGrid.builder(
                itemCount: st.items.length + (st.loadingMore ? 6 : 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, i) {
                  if (i >= st.items.length) {
                    return _skeletonTile();
                  }
                  final tile = st.items[i];
                  return _DiscoverTile(
                    imageUrl: tile.imageUrl,
                    hasMultiple: tile.hasMultiple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(postId: tile.postId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          if (!st.loading && st.items.isNotEmpty && !st.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: Text('— End —')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _topSearch(String currentQuery) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller
                  ..text = _controller.text.isEmpty
                      ? currentQuery
                      : _controller.text,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (q) {
                  ref.read(discoverVCProvider.notifier).refresh(query: q);
                },
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () {
                _controller.clear();
                ref.read(discoverVCProvider.notifier).refresh(query: '');
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorEmpty(String msg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error),
          ),
          child: Text(msg, style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _skeletonTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({
    required this.imageUrl,
    required this.hasMultiple,
    required this.onTap,
  });

  final String imageUrl;
  final bool hasMultiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (c, w, p) {
                if (p == null) return w;
                return Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surface,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            if (hasMultiple)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.collections_bookmark,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
