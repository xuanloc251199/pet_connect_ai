import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_connect_ai/app/core/app_config.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/view/auth_gate.dart';
import '../../feed/view/post_detail_page.dart';
import '../vc/discover_vc.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AuthGate(
      guestTitle: 'Bạn cần đăng nhập',
      guestDesc: 'Đăng nhập/đăng ký để xem nội dung Discover.',
      child: _DiscoverAuthed(),
    );
  }
}

class _DiscoverAuthed extends ConsumerStatefulWidget {
  const _DiscoverAuthed();

  @override
  ConsumerState<_DiscoverAuthed> createState() => _DiscoverAuthedState();
}

class _DiscoverAuthedState extends ConsumerState<_DiscoverAuthed> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  Timer? _debounce;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();

    _scroll.addListener(_onScroll);

    // Load lần đầu sau khi widget mount (tránh nháy do gọi trong build)
    Future.microtask(() {
      if (!mounted) return;
      ref.read(discoverVCProvider.notifier).refresh();
      _didInit = true;
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final st = ref.read(discoverVCProvider);

    // Chặn spam loadMore
    if (st.loading || st.loadingMore || !st.hasMore) return;

    final threshold = _scroll.position.maxScrollExtent - 600;
    if (_scroll.position.pixels >= threshold) {
      ref.read(discoverVCProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submitSearch(String q) {
    final query = q.trim();
    ref.read(discoverVCProvider.notifier).refresh(query: query);
  }

  void _onQueryChanged(String v) {
    // Debounce để tránh refresh liên tục (nếu bạn muốn search realtime)
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final q = _controller.text.trim();
      // Nếu bạn KHÔNG muốn search realtime, có thể xoá hàm này và chỉ onSubmitted.
      // ref.read(discoverVCProvider.notifier).refresh(query: q);
      // => Mặc định mình để comment để tránh gọi API quá nhiều.
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(discoverVCProvider);

    // Đồng bộ text field 1 lần khi init (không set text trong build gây nháy con trỏ)
    if (_didInit && _controller.text.isEmpty && st.query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_controller.text.isEmpty) _controller.text = st.query;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(discoverVCProvider.notifier).refresh(query: st.query),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _topSearch(context, st.query)),
            if (st.loading && st.items.isEmpty)
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
                    if (i >= st.items.length) return _skeletonTile();
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
            if (st.error != null && st.items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: _inlineError(st.error!),
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
      ),
    );
  }

  Widget _topSearch(BuildContext context, String currentQuery) {
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
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                onSubmitted: _submitSearch,
              ),
            ),
            if (_controller.text.isNotEmpty || currentQuery.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () {
                  _controller.clear();
                  ref.read(discoverVCProvider.notifier).refresh(query: '');
                  setState(() {}); // để ẩn icon close ngay
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _inlineError(String msg) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.error),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg, style: const TextStyle(color: Colors.red)),
        ),
      ],
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

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({
    required this.imageUrl,
    required this.hasMultiple,
    required this.onTap,
  });

  final String imageUrl;
  final bool hasMultiple;
  final VoidCallback onTap;

  String _resolveUrl(String raw) {
    final u = raw.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final path = u.startsWith('/') ? u.substring(1) : u;
    return AppConfig.baseStorage + path;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveUrl(imageUrl);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (resolved.isEmpty)
              Container(
                color: AppColors.surface,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textMuted,
                ),
              )
            else
              Image.network(
                resolved,
                fit: BoxFit.cover,
                gaplessPlayback: true, // giảm nháy khi rebuild
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
