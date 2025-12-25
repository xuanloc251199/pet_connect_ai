import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_connect_ai/app/theme/app_images.dart';
import '../../../app/theme/app_colors.dart';

final accountVCProvider = Provider<AccountVC>((ref) => AccountVC());

class AccountVC {
  void goRegister(BuildContext context) {
    // TODO: Navigator.pushNamed(context, '/register');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('TODO: Open Register')));
  }

  void goLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login');
  }
}

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc = ref.read(accountVCProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // LOGO (ảnh)
              Image.asset(
                AppImages.logo,
                width: 210,
                height: 210,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),

              // TITLE (string)
              Text(
                'PET CONNECT',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // SUBTITLE (string)
              Text(
                'Share moments, connect with pet lovers,\n'
                'and discover your pet community!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(flex: 3),

              // BUTTON 1
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => vc.goRegister(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Create An Account',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // BUTTON 2
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => vc.goLogin(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Already Have An Account',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
