import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_connect_ai/app/theme/app_images.dart';

import '../../../app/core/token_storage.dart';
import '../../../app/theme/app_colors.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final splashVCProvider = Provider<SplashVC>((ref) {
  return SplashVC(storage: ref.read(tokenStorageProvider));
});

class SplashVC {
  SplashVC({required this.storage});
  final TokenStorage storage;

  Future<void> goNext(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final token = await storage.readToken();
    final hasToken = token != null && token.isNotEmpty;

    if (!context.mounted) return;

    // ✅ Nếu đã remember (token tồn tại trong secure storage) -> vào Home
    // ✅ Nếu không remember -> token không tồn tại sau khi mở lại app -> vào Account
    Navigator.pushReplacementNamed(context, hasToken ? '/home' : '/account');
  }
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashVCProvider).goNext(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.logo,
                  width: 190,
                  height: 190,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),
                Text(
                  'Pet Connect',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
