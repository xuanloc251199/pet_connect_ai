import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet_connect_ai/features/knowledge/view/knowledge_page.dart';

import '../../../app/core/auth_session.dart';
import '../../../app/theme/app_colors.dart';
import '../../ai_diagnosis/view/ai_diagnosis_page.dart';
import '../../discover/view/discover_page.dart';
import '../../feed/view/home_feed.dart';
import '../../profile/view/profile_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _tab = 0;

  Future<void> _goLogin(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/login');

    final loggedIn = result == true;

    await ref.read(authSessionProvider.notifier).refresh();

    ref.invalidate(isLoggedInProvider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionProvider);
    final isGuest = auth.initialized && !auth.isLoggedIn;

    final pages = <Widget>[
      const HomeFeed(),
      const DiscoverPage(),
      const AiDiagnosisPage(),
      const KnowledgePage(),
      const ProfilePage(),
    ];

    final page = pages[_tab];

    // Guest: lock all tabs except Home (index 0)
    final locked = isGuest && _tab != 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: locked
            ? _GuestLockOverlay(
                child: page,
                title: 'Đăng nhập để tiếp tục',
                desc:
                    'Bạn đang ở chế độ khách. Đăng nhập để dùng đầy đủ tính năng.',
                onLogin: () => _goLogin(context),
              )
            : page,
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChanged: (i) {
          if (isGuest && i != 0) {
            _goLogin(context);
            return;
          }
          setState(() => _tab = i);
        },
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
    const items = [
      ('Home', 'assets/icons/ic_home.svg'),
      ('Discover', 'assets/icons/ic_search.svg'),
      ('New Post', 'assets/icons/ic_plus.svg'),
      ('Knowledge', 'assets/icons/ic_knowledge.svg'),
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

class _GuestLockOverlay extends StatelessWidget {
  const _GuestLockOverlay({
    required this.child,
    required this.title,
    required this.desc,
    required this.onLogin,
  });

  final Widget child;
  final String title;
  final String desc;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: true,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Opacity(opacity: 0.55, child: child),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onLogin,
                    child: const Text(
                      'Đăng nhập / Đăng ký',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
