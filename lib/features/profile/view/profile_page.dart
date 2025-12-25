import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_connect_ai/app/theme/app_images.dart';

import '../../../app/core/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/view/auth_gate.dart';
import '../../feed/view/post_detail_page.dart';
import '../vc/profile_posts_vc.dart';
import '../vc/profile_vc.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AuthGate(
      guestTitle: 'Bạn cần đăng nhập',
      guestDesc: 'Đăng nhập/đăng ký để xem Profile.',
      child: _ProfileAuthed(),
    );
  }
}

class _ProfileAuthed extends ConsumerStatefulWidget {
  const _ProfileAuthed();

  @override
  ConsumerState<_ProfileAuthed> createState() => _ProfileAuthedState();
}

class _ProfileAuthedState extends ConsumerState<_ProfileAuthed> {
  ProviderSubscription<ProfileState>? _subProfile;
  ProviderSubscription<ProfilePostsState>? _subPosts;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(profileVCProvider.notifier).load();
      ref.read(profilePostsVCProvider.notifier).load();
    });

    _scroll.addListener(_onScroll);

    _subProfile = ref.listenManual(profileVCProvider, (prev, next) {
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

    _subPosts = ref.listenManual(profilePostsVCProvider, (prev, next) {
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

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final pst = ref.read(profilePostsVCProvider);
    if (pst.loading || pst.loadingMore || !pst.hasMore) return;

    final threshold = _scroll.position.maxScrollExtent - 700;
    if (_scroll.position.pixels >= threshold) {
      ref.read(profilePostsVCProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _subProfile?.close();
    _subPosts?.close();
    super.dispose();
  }

  String? _avatarUrl(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;

    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    final path = s.startsWith('/') ? s.substring(1) : s;

    if (path.startsWith('storage/')) {
      return '${AppConfig.baseUrl}/$path';
    }

    if (path.startsWith('avatars/')) {
      return '${AppConfig.baseStorage}$path';
    }

    return '${AppConfig.baseStorage}/$path';
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await ref.read(profileVCProvider.notifier).logout();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(profileVCProvider);
    final pst = ref.watch(profilePostsVCProvider);

    const coverFallback = 'assets/images/demo/cover.png';
    const avatarFallback = 'assets/images/demo/avatar_1.png';

    final d = st.data;

    final name = (d?['name'] ?? d?['username'] ?? '—').toString();
    final rawBio = (d?['bio'] ?? '').toString().trim();
    final bio = rawBio.isEmpty
        ? 'No bio yet. Tap Edit Profile to add one.'
        : rawBio;

    final postsCount = (d?['posts_count'] ?? 0).toString();
    final followers = (d?['followers_count'] ?? 0).toString();
    final following = (d?['following_count'] ?? 0).toString();

    final avatarUrl = _avatarUrl(d?['avatar'] as String?);
    final coverUrl = _avatarUrl(d?['cover_photo'] as String?);
    final isPrivate = (d?['is_private'] ?? false) as bool;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: (st.loading && d == null)
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(profileVCProvider.notifier).load();
                  await ref.read(profilePostsVCProvider.notifier).load();
                },
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _TopBar(
                        onSettings: () =>
                            Navigator.pushNamed(context, '/settings'),
                        onLogout: (st.uploading || st.loading) ? null : _logout,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Header(
                        coverUrl: coverUrl,
                        avatarUrl: avatarUrl,
                        coverFallback: coverFallback,
                        avatarFallback: avatarFallback,
                        username: name,
                        bio: bio,
                        posts: postsCount,
                        followers: followers,
                        following: following,
                        uploading: st.uploading,
                        onEdit: () =>
                            Navigator.pushNamed(context, '/edit-profile'),
                      ),
                    ),
                    if (isPrivate)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'This account is private. Only followers can see posts.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      _ProfilePostsGrid(
                        loading: pst.loading,
                        loadingMore: pst.loadingMore,
                        hasMore: pst.hasMore,
                        posts: pst.posts,
                      ),
                    if (!isPrivate && pst.loadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings, required this.onLogout});

  final VoidCallback onSettings;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
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
            'Pet Connect',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            color: Colors.redAccent,
            tooltip: 'Đăng xuất',
          ),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
            tooltip: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.coverUrl,
    required this.avatarUrl,
    required this.coverFallback,
    required this.avatarFallback,
    required this.username,
    required this.bio,
    required this.posts,
    required this.followers,
    required this.following,
    required this.uploading,
    required this.onEdit,
  });

  final String? coverUrl;
  final String? avatarUrl;
  final String coverFallback;
  final String avatarFallback;

  final String username;
  final String bio;

  final String posts;
  final String followers;
  final String following;

  final bool uploading;
  final VoidCallback onEdit;

  Widget _networkOrAsset({
    required String? url,
    required String fallbackAsset,
    required BoxFit fit,
  }) {
    final u = (url ?? '').trim();
    if (u.isEmpty) return Image.asset(fallbackAsset, fit: fit);

    return Image.network(
      u,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: fit),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: _networkOrAsset(
            url: coverUrl,
            fallbackAsset: coverFallback,
            fit: BoxFit.cover,
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -44),
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                      color: Colors.black.withOpacity(0.12),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _networkOrAsset(
                    url: avatarUrl,
                    fallbackAsset: avatarFallback,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                username,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2AA6FF),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(value: posts, label: 'Posts'),
                    _Stat(value: followers, label: 'Followers'),
                    _Stat(value: following, label: 'Following'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: uploading ? null : onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: uploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ProfilePostsGrid extends StatelessWidget {
  const _ProfilePostsGrid({
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.posts,
  });

  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final List<Map<String, dynamic>> posts;

  String _resolveThumb(String raw) {
    final u = raw.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final path = u.startsWith('/') ? u.substring(1) : u;
    return AppConfig.baseStorage + path;
  }

  @override
  Widget build(BuildContext context) {
    if (loading && posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!loading && posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 18, 14, 18),
          child: Center(
            child: Text(
              'No posts yet.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: posts.length,
        itemBuilder: (_, i) {
          final post = posts[i];
          final postId = (post['id'] as num?)?.toInt() ?? 0;
          final rawThumb = (post['thumbnail'] ?? '').toString();
          final imageUrl = _resolveThumb(rawThumb);
          final imagesCount = (post['images_count'] as num?)?.toInt() ?? 0;

          return _PostTile(
            postId: postId,
            imageUrl: imageUrl,
            hasMulti: imagesCount > 1,
          );
        },
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.postId,
    required this.imageUrl,
    required this.hasMulti,
  });

  final int postId;
  final String imageUrl;
  final bool hasMulti;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () {
            if (postId <= 0) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailPage(postId: postId)),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isEmpty)
                const Center(
                  child: Icon(
                    Icons.photo_outlined,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  loadingBuilder: (c, w, p) {
                    if (p == null) return w;
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              if (hasMulti)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.copy,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
