import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../vc/profile_vc.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileVCProvider.notifier).load());
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    await ref.read(profileVCProvider.notifier).uploadAvatar(File(x.path));
  }

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    await ref.read(profileVCProvider.notifier).uploadCover(File(x.path));
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(profileVCProvider);
    final vc = ref.read(profileVCProvider.notifier);

    // fallback assets nếu API chưa có
    const coverFallback = 'assets/images/demo/cover.png';
    const avatarFallback = 'assets/images/demo/avatar_1.png';

    // grid demo (sau này đổi thành API posts của user)
    const grid = [
      'assets/images/demo/post_6.png',
      'assets/images/demo/post_6.png',
      'assets/images/demo/post_6.png',
      'assets/images/demo/post_6.png',
      'assets/images/demo/post_6.png',
      'assets/images/demo/post_6.png',
      'assets/images/demo/post_6.png',
      'assets/images/demo/post_6.png',
      'assets/images/demo/post_6.png',
    ];

    final d = st.data;

    final username = (d?['username'] ?? '—').toString();
    final bio = (d?['bio'] ?? '—').toString();

    final posts = (d?['posts_count'] ?? 0).toString();
    final followers = (d?['followers_count'] ?? 0).toString();
    final following = (d?['following_count'] ?? 0).toString();

    final avatarUrl = d?['avatar'] as String?;
    final coverUrl = d?['cover_photo'] as String?;
    final isPrivate = (d?['is_private'] ?? false) as bool;

    ref.listen(profileVCProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: st.loading && d == null
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _TopBar(
                      onSettings: () =>
                          Navigator.pushNamed(context, '/settings'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Header(
                      coverUrl: coverUrl,
                      coverFallbackAsset: coverFallback,
                      avatarUrl: avatarUrl,
                      avatarFallbackAsset: avatarFallback,
                      username: username,
                      bio: bio,
                      posts: posts,
                      followers: followers,
                      following: following,
                      isPrivate: isPrivate,
                      uploading: st.uploading,
                      onPickAvatar: _pickAvatar,
                      onPickCover: _pickCover,
                      onTogglePrivate: (v) => vc.togglePrivate(v),
                      onEdit: () =>
                          Navigator.pushNamed(context, '/edit-profile'),
                    ),
                  ),

                  // Privacy: private -> ẩn grid + hiển thị lock note
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
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: grid.length,
                        itemBuilder: (_, i) => _GridTile(image: grid[i]),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});
  final VoidCallback onSettings;

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
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.coverUrl,
    required this.coverFallbackAsset,
    required this.avatarUrl,
    required this.avatarFallbackAsset,
    required this.username,
    required this.bio,
    required this.posts,
    required this.followers,
    required this.following,
    required this.isPrivate,
    required this.uploading,
    required this.onPickCover,
    required this.onPickAvatar,
    required this.onTogglePrivate,
    required this.onEdit,
  });

  final String? coverUrl;
  final String coverFallbackAsset;

  final String? avatarUrl;
  final String avatarFallbackAsset;

  final String username;
  final String bio;

  final String posts;
  final String followers;
  final String following;

  final bool isPrivate;
  final bool uploading;

  final VoidCallback onPickCover;
  final VoidCallback onPickAvatar;
  final ValueChanged<bool> onTogglePrivate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final coverProvider = (coverUrl != null && coverUrl!.isNotEmpty)
        ? NetworkImage(coverUrl!)
        : AssetImage(coverFallbackAsset) as ImageProvider;

    final avatarProvider = (avatarUrl != null && avatarUrl!.isNotEmpty)
        ? NetworkImage(avatarUrl!)
        : AssetImage(avatarFallbackAsset) as ImageProvider;

    return Column(
      children: [
        // Cover (tap upload)
        GestureDetector(
          onTap: uploading ? null : onPickCover,
          child: Stack(
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: Image(image: coverProvider, fit: BoxFit.cover),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    uploading ? 'Uploading...' : 'Edit cover',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Avatar overlap
        Transform.translate(
          offset: const Offset(0, -44),
          child: Column(
            children: [
              // Avatar (tap upload)
              GestureDetector(
                onTap: uploading ? null : onPickAvatar,
                child: Container(
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

              // Stats (from API)
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

              // Bio (from API)
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

              const SizedBox(height: 10),

              // Privacy toggle (from API)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Private account',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Switch(
                      value: isPrivate,
                      onChanged: uploading ? null : onTogglePrivate,
                      activeColor: AppColors.accent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Edit button
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

class _GridTile extends StatelessWidget {
  const _GridTile({required this.image});
  final String image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover),
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
              child: const Icon(Icons.copy, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
