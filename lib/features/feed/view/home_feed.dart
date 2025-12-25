import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_images.dart';
import '../../../app/theme/app_strings.dart';

import '../../posts/create_post/view/create_post_page.dart';
import '../../profile/view/settings_page.dart';
import '../model/feed_models.dart';
import '../vc/feed_vc.dart';
import 'post_detail_page.dart';

class HomeFeed extends ConsumerStatefulWidget {
  const HomeFeed({super.key});

  @override
  ConsumerState<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends ConsumerState<HomeFeed> {
  ProviderSubscription<FeedState>? _sub;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(feedVCProvider.notifier).load());

    _sub = ref.listenManual(feedVCProvider, (prev, next) {
      if (!mounted) return;
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.close();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );

    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      final created = FeedPost.fromApi(result);
      ref.read(feedVCProvider.notifier).prependLocal(created);

      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _openPostDetail(FeedPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(postId: post.id, initialPost: post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(feedVCProvider);
    final vc = ref.read(feedVCProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => vc.load(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.maxScrollExtent == 0) return false;
          final trigger = n.metrics.pixels > n.metrics.maxScrollExtent - 240;
          if (trigger) vc.loadMore();
          return false;
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _HomeTopBar()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: _CreatePostComposer(onTap: _openCreatePost),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: _PromoBanner(onClose: () {}),
              ),
            ),

            if (st.loading && st.posts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (!st.loading && st.posts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Center(
                    child: Text(
                      AppStrings.noPublicPosts,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: st.posts.length + (st.loadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i >= st.posts.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  final post = st.posts[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _PostCard(
                      post: post,
                      onLike: () => vc.toggleLike(post.id),
                      onComment: () => _openPostDetail(post),
                      onViewAllComments: () => _openPostDetail(post),
                    ),
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(AppImages.logo, width: 26, height: 26),
          const SizedBox(width: 10),
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          _IconWithBadge(assetSvg: AppIcons.icBell, badge: 0, onTap: () {}),
          const SizedBox(width: 12),
          _IconWithBadge(assetSvg: AppIcons.icMessage, badge: 2, onTap: () {}),
          const SizedBox(width: 12),
          _IconWithBadge(
            assetSvg: AppIcons.icSettings,
            badge: 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.assetSvg,
    required this.badge,
    required this.onTap,
  });

  final String assetSvg;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              assetSvg,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
            if (badge > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: 10,
            child: InkWell(
              onTap: onClose,
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 130, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  AppStrings.promoTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 8),
                _PromoDesc(),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 0,
            child: Image.asset(
              AppImages.dogBanner,
              height: 108,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoDesc extends StatelessWidget {
  const _PromoDesc();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.promoDesc,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
        height: 1.25,
      ),
    );
  }
}

class _CreatePostComposer extends StatelessWidget {
  const _CreatePostComposer({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.edit, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.shareSomething,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return '${max(1, diff.inSeconds)}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  final w = (diff.inDays / 7).floor();
  if (w < 4) return '${w}w';
  final m = (diff.inDays / 30).floor();
  return '${max(1, m)}mo';
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onViewAllComments,
  });

  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onViewAllComments;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final _page = PageController();
  int _idx = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(p.avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.userName,
                      style: const TextStyle(
                        color: Color(0xFF2AA6FF),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(p.createdAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.more_horiz, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (p.content.isNotEmpty)
            Text(
              p.content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),

          if (p.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: widget.onComment, // tap ảnh -> mở detail (comment)
              child: _media(p.images),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              _actionIcon(
                AppIcons.icHeart,
                AppIcons.icHeartActive,
                widget.onLike,
                active: p.isLiked,
              ),
              const SizedBox(width: 14),
              _actionIcon(
                AppIcons.icComment,
                AppIcons.icComment,
                widget.onComment,
              ),
              const SizedBox(width: 14),
              _actionIcon(AppIcons.icSent, AppIcons.icSent, () {}),
              const Spacer(),
              Text(
                '${p.likes} ${AppStrings.likes}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: widget.onViewAllComments,
            child: const Text(
              AppStrings.viewAllComments,
              style: TextStyle(
                color: Color(0xFF6AAEAF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? url) {
    final u = (url ?? '').trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        color: AppColors.primarySoft,
        child: u.isEmpty
            ? const Icon(Icons.person, color: AppColors.primary)
            : Image.network(
                u,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: AppColors.primary),
                loadingBuilder: (c, w, p) {
                  if (p == null) return w;
                  return const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _actionIcon(
    String svg,
    String svgActive,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SvgPicture.asset(
        active ? svgActive : svg,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          active ? Colors.red : AppColors.textSecondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _media(List<String> images) {
    final total = images.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: PageView.builder(
              controller: _page,
              itemCount: total,
              onPageChanged: (i) {
                if (i == _idx) return;
                setState(() => _idx = i);
              },
              itemBuilder: (_, i) => Image.network(
                images[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                loadingBuilder: (c, w, p) {
                  if (p == null) return w;
                  return Container(
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_idx + 1}/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          if (total > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final active = i == _idx;
                  return Container(
                    width: active ? 10 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
