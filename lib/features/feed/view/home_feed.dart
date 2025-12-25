import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet_connect_ai/app/core/app_config.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_images.dart';
import '../../../app/theme/app_strings.dart';

import '../../auth/vc/auth_providers.dart';
import '../../posts/create_post/view/create_post_page.dart';
import '../../profile/view/settings_page.dart';
import '../model/feed_models.dart';
import '../vc/feed_vc.dart';
import 'post_detail_page.dart';

const int kGuestVisiblePosts = 3;

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final storage = ref.read(tokenStorageProvider);
  final token = await storage.readToken();
  return token != null && token.trim().isNotEmpty;
});

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

      final msg = next.error ?? '';
      final prevMsg = prev?.error ?? '';

      if (msg.isNotEmpty &&
          msg != prevMsg &&
          msg.toLowerCase().contains('unauthenticated')) {
        return;
      }

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

  Future<void> _goLogin() async {
    await Navigator.pushNamed(context, '/login');

    ref.invalidate(isLoggedInProvider);

    ref.read(feedVCProvider.notifier).load();
  }

  Future<void> _openCreatePost(bool isLoggedIn) async {
    if (!isLoggedIn) {
      _goLogin();
      return;
    }

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

  void _openPostDetail({
    required FeedPost post,
    required bool isLoggedIn,
    required bool canView,
  }) {
    // Guest bấm vào bài blur -> chuyển login
    if (!isLoggedIn && !canView) {
      _goLogin();
      return;
    }

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

    final authAsync = ref.watch(isLoggedInProvider);
    final isLoggedIn = authAsync.maybeWhen(data: (v) => v, orElse: () => true);

    final guestMax = min(st.posts.length, kGuestVisiblePosts + 1);

    final itemCount = isLoggedIn
        ? st.posts.length + (st.loadingMore ? 1 : 0)
        : guestMax;

    return RefreshIndicator(
      onRefresh: () => vc.load(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          //   Guest không load more
          if (!isLoggedIn) return false;

          if (n.metrics.maxScrollExtent == 0) return false;
          final trigger = n.metrics.pixels > n.metrics.maxScrollExtent - 240;
          if (trigger) vc.loadMore();
          return false;
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _HomeTopBar(onRequireLogin: _goLogin)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: _CreatePostComposer(
                  onTap: () => _openCreatePost(isLoggedIn),
                ),
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
                itemCount: itemCount,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  // load more indicator (logged in only)
                  if (isLoggedIn && i >= st.posts.length) {
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

                  if (i >= st.posts.length) return const SizedBox.shrink();

                  final post = st.posts[i];

                  //   canView:
                  // - logged in: luôn true
                  // - guest: chỉ 0..2 (3 bài) là true
                  final canView = isLoggedIn || i < kGuestVisiblePosts;

                  final card = Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _PostCard(
                      post: post,
                      isLoggedIn: isLoggedIn,
                      onRequireLogin: _goLogin,
                      onLike: () => vc.toggleLike(post.id),
                      onComment: () => _openPostDetail(
                        post: post,
                        isLoggedIn: isLoggedIn,
                        canView: canView,
                      ),
                      onViewAllComments: () => _openPostDetail(
                        post: post,
                        isLoggedIn: isLoggedIn,
                        canView: canView,
                      ),
                    ),
                  );

                  //   Guest: bài thứ 4 (index=3) blur
                  if (!isLoggedIn && i == kGuestVisiblePosts) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _LockedOverlay(child: card, onLogin: _goLogin),
                    );
                  }

                  return card;
                },
              ),

            //   Guest: chỉ hiện CTA nhỏ 1 lần sau list (không show "xem thêm")
            if (!isLoggedIn && st.posts.length > kGuestVisiblePosts)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Đăng nhập để xem thêm bài viết và tương tác.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _goLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        ),
      ),
    );
  }
}

class _LockedOverlay extends StatelessWidget {
  const _LockedOverlay({required this.child, required this.onLogin});

  final Widget child;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Opacity(opacity: 0.28, child: child),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.45),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: ElevatedButton.icon(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text(
                'Đăng nhập để xem',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.onRequireLogin});
  final VoidCallback onRequireLogin;

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
          _IconWithBadge(
            assetSvg: AppIcons.icBell,
            badge: 0,
            onTap: onRequireLogin,
          ),
          const SizedBox(width: 12),
          _IconWithBadge(
            assetSvg: AppIcons.icMessage,
            badge: 2,
            onTap: onRequireLogin,
          ),
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
    required this.isLoggedIn,
    required this.onRequireLogin,
    required this.onLike,
    required this.onComment,
    required this.onViewAllComments,
  });

  final FeedPost post;
  final bool isLoggedIn;
  final VoidCallback onRequireLogin;

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
            GestureDetector(onTap: widget.onComment, child: _media(p.images)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _actionIcon(
                AppIcons.icHeart,
                AppIcons.icHeartActive,
                widget.isLoggedIn ? widget.onLike : widget.onRequireLogin,
                active: p.isLiked,
              ),
              const SizedBox(width: 14),
              _actionIcon(
                AppIcons.icComment,
                AppIcons.icComment,
                widget.onComment,
              ),
              const SizedBox(width: 14),
              _actionIcon(
                AppIcons.icSent,
                AppIcons.icSent,
                widget.onRequireLogin,
              ),
              const Spacer(),
              Text(
                '${p.likes} ${AppStrings.likes} ● ${p.comments} ${AppStrings.comments}',
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
                AppConfig.baseStorage + u,
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
                AppConfig.baseStorage + images[i],
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
