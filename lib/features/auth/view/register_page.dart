import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../model/auth_models.dart';
import '../vc/register_vc.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final nameCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool hide = true;
  bool agree = false;

  bool get has8 => passCtrl.text.length >= 8;
  bool get hasNumber => RegExp(r'\d').hasMatch(passCtrl.text);
  bool get hasUpperLower =>
      RegExp(r'[A-Z]').hasMatch(passCtrl.text) &&
      RegExp(r'[a-z]').hasMatch(passCtrl.text);

  @override
  void dispose() {
    nameCtrl.dispose();
    userCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(registerVCProvider);

    ref.listen(registerVCProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }

      if (prev?.loading == true &&
          next.loading == false &&
          next.error == null) {
        Navigator.pushReplacementNamed(
          context,
          '/otp',
          arguments: emailCtrl.text.trim(),
        );
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
              "Welcome!\nLet’s get you started.",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 18),

            AppTextField(
              label: 'Name',
              hint: 'Enter your name',
              controller: nameCtrl,
              prefix: const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Username',
              hint: 'Enter your username',
              controller: userCtrl,
              prefix: const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Email',
              hint: 'Ex: abc@example.com',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 12),
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

            const SizedBox(height: 10),
            _RequirementRow(ok: has8, text: 'At least 8 characters'),
            _RequirementRow(ok: hasNumber, text: 'At least 1 number'),
            _RequirementRow(
              ok: hasUpperLower,
              text: 'Both upper and lower case letters',
            ),

            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: agree,
                  onChanged: (v) => setState(() => agree = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'By creating an account, you agree to our\nTerms and Conditions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (!agree || st.loading)
                    ? null
                    : () => ref
                          .read(registerVCProvider.notifier)
                          .register(
                            RegisterPayload(
                              name: nameCtrl.text.trim(),
                              username: userCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text,
                            ),
                          ),
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
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                InkWell(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    'Login',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2AA6A0),
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

class _RequirementRow extends StatelessWidget {
  final bool ok;
  final String text;
  const _RequirementRow({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            ok
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: ok ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ok ? AppColors.success : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
