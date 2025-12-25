import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet_connect_ai/features/ai_diagnosis/view/ai_diagnosis_page.dart';
import '../../../app/theme/app_colors.dart';
import '../../posts/create_post/view/create_post_page.dart';
import '../../profile/view/profile_page.dart';
import '../../profile/view/settings_page.dart';
import '../../discover/view/discover_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeFeed(),
      const DiscoverPage(),
      const AiDiagnosisPage(),
      const _PlaceholderPage(title: 'Community'),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _HomeFeed extends StatelessWidget {
  const _HomeFeed();

  @override
  Widget build(BuildContext context) {
    final posts = <_PostVm>[
      _PostVm(
        userName: 'FluffyAdventures',
        avatarAsset: 'assets/images/demo/avatar_1.png',
        timeAgo: '48m',
        content:
            'Just got back from our first agility training session! 🐕‍🦺🎉\nFluffy nailed the course! 🏅',
        hashtags: '#PetTraining #FluffyWins #PawPals',
        images: const [
          'assets/images/demo/post_1.png',
          'assets/images/demo/post_2.png',
          'assets/images/demo/post_3.png',
          'assets/images/demo/post_4.png',
          'assets/images/demo/post_5.png',
        ],
        likes: 2619,
      ),
      _PostVm(
        userName: 'Meowmas DVO',
        avatarAsset: 'assets/images/demo/avatar_2.png',
        timeAgo: '48m',
        content: 'Anyone want to meetup at Azuela Cove?',
        hashtags: '',
        images: const [],
        likes: 2619,
      ),
      _PostVm(
        userName: 'Meowmas DVO',
        avatarAsset: 'assets/images/demo/avatar_2.png',
        timeAgo: '48m',
        content: 'Meet Maxine! My bunso <3',
        hashtags: '',
        images: const ['assets/images/demo/post_6.png'],
        likes: 2619,
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HomeTopBar()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: _CreatePostComposer(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostPage(
                      onPosted: () {
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                );

                // TODO: refresh feed
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: _PromoBanner(onClose: () {}),
          ),
        ),
        SliverList.separated(
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PostCard(vm: posts[i]),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
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
          // Logo
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
          _IconWithBadge(
            assetSvg: 'assets/icons/ic_bell.svg',
            badge: 0,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _IconWithBadge(
            assetSvg: 'assets/icons/ic_message.svg',
            badge: 2,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _IconWithBadge(
            assetSvg: 'assets/icons/ic_settings.svg',
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
              children: [
                const Text(
                  'PawPalPro\nComing Soon!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exclusive perks and features are\ncoming your way. Stay tuned for\nmore details!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 0,
            child: Image.asset(
              'assets/images/demo/dog_banner.png',
              height: 108,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostVm {
  final String userName;
  final String avatarAsset;
  final String timeAgo;
  final String content;
  final String hashtags;
  final List<String> images;
  final int likes;

  const _PostVm({
    required this.userName,
    required this.avatarAsset,
    required this.timeAgo,
    required this.content,
    required this.hashtags,
    required this.images,
    required this.likes,
  });
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.vm});

  final _PostVm vm;

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
    final vm = widget.vm;

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
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(vm.avatarAsset),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.userName,
                      style: const TextStyle(
                        color: Color(0xFF2AA6FF),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vm.timeAgo,
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
                onTap: () {},
                child: const Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Text
          if (vm.content.isNotEmpty) ...[
            Text(
              vm.content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
          if (vm.hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              vm.hashtags,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Media
          if (vm.images.isNotEmpty) _media(vm),

          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              _actionIcon('assets/icons/ic_heart.svg', () {}),
              const SizedBox(width: 14),
              _actionIcon('assets/icons/ic_comment.svg', () {}),
              const SizedBox(width: 14),
              _actionIcon('assets/icons/ic_send.svg', () {}),
              const Spacer(),
              Text(
                '${vm.likes.toString()} likes',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'View all 16 comments',
            style: TextStyle(
              color: Color(0xFF6AAEAF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(String svg, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SvgPicture.asset(
        svg,
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(
          AppColors.textSecondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _media(_PostVm vm) {
    final total = vm.images.length;

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
              onPageChanged: (i) => setState(() => _idx = i),
              itemBuilder: (_, i) =>
                  Image.asset(vm.images[i], fit: BoxFit.cover),
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

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // SVG icon names: bạn thay bằng file thật trong assets/icons/
    const items = [
      ('Home', 'assets/icons/ic_home.svg'),
      ('Discover', 'assets/icons/ic_search.svg'),
      ('New Post', 'assets/icons/ic_plus.svg'),
      ('Community', 'assets/icons/ic_users.svg'),
      ('Profile', 'assets/icons/ic_profile.svg'),
    ];

    return Container(
      height: 74,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, -4),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (i) {
          final (label, icon) = items[i];
          final active = i == index;

          // Center button (New Post)
          if (i == 2) {
            return Expanded(
              child: Center(
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      icon,
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    icon,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      active ? AppColors.primary : AppColors.iconInactive,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
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
                "Share something about your pet…",
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
