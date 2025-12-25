import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../vc/login_vc.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool hide = true;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(loginVCProvider);
    final vc = ref.read(loginVCProvider.notifier);

    ref.listen(loginVCProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        vc.clearError();
      }

      // Login success -> Home
      if (prev?.loading == true &&
          next.loading == false &&
          next.error == null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back!\nLet’s sign you in.",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Email',
              hint: 'Ex: abc@example.com',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Password',
              hint: '••••••••',
              controller: passCtrl,
              obscure: hide,
              prefix: const Icon(Icons.lock_outline_rounded),
              suffix: IconButton(
                onPressed: () => setState(() => hide = !hide),
                icon: Icon(
                  hide
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Remember + Forgot
            Row(
              children: [
                Checkbox(
                  value: st.remember,
                  onChanged: (v) => vc.toggleRemember(v ?? true),
                ),
                Text(
                  'Remember me',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot password?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2AA6A0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: st.loading
                    ? null
                    : () async {
                        await vc.login(
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text,
                        );

                        if (!context.mounted) return;

                        final next = ref.read(loginVCProvider);

                        if (next.error == null) {
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(next.error!)));
                          vc.clearError();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: st.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don’t have an account yet? ",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHighlight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
