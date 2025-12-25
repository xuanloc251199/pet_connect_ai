import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../vc/profile_vc.dart';
import '../vc/profile_posts_vc.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  ProviderSubscription<ProfileState>? _subProfile;
  ProviderSubscription<ProfilePostsState>? _subPosts;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(profileVCProvider.notifier).load();
      ref.read(profilePostsVCProvider.notifier).load();
    });

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

  @override
  void dispose() {
    _subProfile?.close();
    _subPosts?.close();
    super.dispose();
  }

  String _mediaBase() {
    var b = AppConfig.baseUrl;
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    b = b.replaceFirst(RegExp(r'/api/v\d+$'), '');
    return b;
  }

  String _normalizeUrl(String? path) {
    if (path == null) return '';
    final p = path.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('file://')) return p;

    final base = _mediaBase();
    if (p.startsWith('/')) return '$base$p';
    return '$base/$p';
  }

  ImageProvider _imageProvider(String? url, String fallbackAsset) {
    final u = _normalizeUrl(url);
    if (u.isEmpty) return AssetImage(fallbackAsset);

    if (u.startsWith('file://')) {
      try {
        return FileImage(File.fromUri(Uri.parse(u)));
      } catch (_) {
        return AssetImage(fallbackAsset);
      }
    }

    return NetworkImage(u);
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
    final pVc = ref.read(profilePostsVCProvider.notifier);

    const coverFallback = 'assets/images/demo/cover.png';
    const avatarFallback = 'assets/images/demo/avatar_1.png';

    final d = st.data;

    final username = (d?['username'] ?? d?['name'] ?? '—').toString();
    final rawBio = (d?['bio'] ?? '').toString().trim();
    final bio = rawBio.isEmpty
        ? 'No bio yet. Tap Edit Profile to add one.'
        : rawBio;

    final postsCount = (d?['posts_count'] ?? 0).toString();
    final followers = (d?['followers_count'] ?? 0).toString();
    final following = (d?['following_count'] ?? 0).toString();

    final avatarUrl = d?['avatar'] as String?;
    final coverUrl = d?['cover_photo'] as String?;
    final isPrivate = (d?['is_private'] ?? false) as bool;

    final coverProvider = _imageProvider(coverUrl, coverFallback);
    final avatarProvider = _imageProvider(avatarUrl, avatarFallback);

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
                        coverProvider: coverProvider,
                        avatarProvider: avatarProvider,
                        username: username,
                        bio: bio,
                        posts: postsCount,
                        followers: followers,
                        following: following,
                        uploading: st.uploading,
                        onEdit: () =>
                            Navigator.pushNamed(context, '/edit-profile'),
                      ),
                    ),

                    // Private -> ẩn feed
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
                            child: Row(
                              children: const [
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
                        onLoadMore: () => pVc.loadMore(),
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
          Image.asset('assets/images/logo/logo.png', width: 26, height: 26),
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
    required this.coverProvider,
    required this.avatarProvider,
    required this.username,
    required this.bio,
    required this.posts,
    required this.followers,
    required this.following,
    required this.uploading,
    required this.onEdit,
  });

  final ImageProvider coverProvider;
  final ImageProvider avatarProvider;

  final String username;
  final String bio;

  final String posts;
  final String followers;
  final String following;

  final bool uploading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: Image(image: coverProvider, fit: BoxFit.cover),
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
                child: CircleAvatar(backgroundImage: avatarProvider),
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
    required this.onLoadMore,
  });

  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final List<Map<String, dynamic>> posts;
  final VoidCallback onLoadMore;

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
        itemCount: posts.length + (hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= posts.length) {
            Future.microtask(onLoadMore);
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final post = posts[i];
          final imageUrl = (post['thumbnail'] ?? '').toString();
          final imagesCount = (post['images_count'] as num?)?.toInt() ?? 0;

          return _PostTile(
            imageUrl: imageUrl,
            hasMulti: imagesCount > 1,
            onTap: () {
              // TODO: open post detail
              // Navigator.pushNamed(context, '/posts/${post['id']}');
            },
          );
        },
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.imageUrl,
    required this.hasMulti,
    required this.onTap,
  });

  final String imageUrl;
  final bool hasMulti;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
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
