import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/view/auth_gate.dart';
import '../model/knowledge_article.dart';
import '../vc/knowledge_vc.dart';
import 'knowledge_detail_page.dart';

class KnowledgePage extends ConsumerWidget {
  const KnowledgePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AuthGate(
      guestTitle: 'Bạn cần đăng nhập',
      guestDesc: 'Đăng nhập/đăng ký để xem kho tri thức.',
      child: _KnowledgeAuthed(),
    );
  }
}

class _KnowledgeAuthed extends ConsumerStatefulWidget {
  const _KnowledgeAuthed();

  @override
  ConsumerState<_KnowledgeAuthed> createState() => _KnowledgeAuthedState();
}

class _KnowledgeAuthedState extends ConsumerState<_KnowledgeAuthed> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  Timer? _debounce;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();

    _scroll.addListener(_onScroll);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(knowledgeVCProvider.notifier).refresh();
      _didInit = true;
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final st = ref.read(knowledgeVCProvider);
    if (st.loading || st.loadingMore || !st.hasMore) return;

    final threshold = _scroll.position.maxScrollExtent - 600;
    if (_scroll.position.pixels >= threshold) {
      ref.read(knowledgeVCProvider.notifier).loadMore();
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
    final st = ref.read(knowledgeVCProvider);
    ref
        .read(knowledgeVCProvider.notifier)
        .refresh(query: q.trim(), pet: st.pet);
  }

  void _onQueryChanged(String v) {
    // Nếu muốn search realtime, bật refresh trong debounce.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      // default: không gọi API realtime để tránh tốn request + nháy
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(knowledgeVCProvider);

    if (_didInit && _controller.text.isEmpty && st.query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_controller.text.isEmpty) _controller.text = st.query;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(knowledgeVCProvider.notifier)
            .refresh(query: st.query, pet: st.pet),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _topSearch(st.query)),
            SliverToBoxAdapter(child: _petFilter(st.pet)),

            if (st.loading && st.items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (st.error != null && st.items.isEmpty)
              SliverFillRemaining(child: _errorEmpty(st.error!))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                sliver: SliverList.separated(
                  itemCount: st.items.length + (st.loadingMore ? 2 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i >= st.items.length) return _skeletonCard();
                    final a = st.items[i];
                    return _KnowledgeCard(
                      a: a,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KnowledgeDetailPage(article: a),
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
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
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
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Tìm bệnh / triệu chứng / từ khoá...',
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
                  final st = ref.read(knowledgeVCProvider);
                  ref
                      .read(knowledgeVCProvider.notifier)
                      .refresh(query: '', pet: st.pet);
                  setState(() {});
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

  Widget _petFilter(KnowledgePetType current) {
    void apply(KnowledgePetType p) {
      final q = _controller.text.trim();
      ref.read(knowledgeVCProvider.notifier).refresh(pet: p, query: q);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          _Pill(
            label: 'Tất cả',
            active: current == KnowledgePetType.all,
            onTap: () => apply(KnowledgePetType.all),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: 'Chó',
            active: current == KnowledgePetType.dog,
            onTap: () => apply(KnowledgePetType.dog),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: 'Mèo',
            active: current == KnowledgePetType.cat,
            onTap: () => apply(KnowledgePetType.cat),
          ),
          const SizedBox(width: 8),
          _Pill(
            label: 'Cả hai',
            active: current == KnowledgePetType.both,
            onTap: () => apply(KnowledgePetType.both),
          ),
        ],
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

Widget _skeletonCard() {
  return Container(
    height: 120,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({required this.a, required this.onTap});

  final KnowledgeArticle a;
  final VoidCallback onTap;

  String _petBadge(KnowledgePetType p) {
    switch (p) {
      case KnowledgePetType.dog:
        return 'Chó';
      case KnowledgePetType.cat:
        return 'Mèo';
      case KnowledgePetType.both:
        return 'Chó • Mèo';
      case KnowledgePetType.all:
        return 'Tất cả';
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _petBadge(a.pet);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                _DangerDots(level: a.dangerLevel),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              a.title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            if (a.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: a.tags.take(4).map((t) => _Tag(text: t)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DangerDots extends StatelessWidget {
  const _DangerDots({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final lv = level.clamp(1, 5);
    return Row(
      children: List.generate(5, (i) {
        final active = i < lv;
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: active ? Colors.redAccent : AppColors.border,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
