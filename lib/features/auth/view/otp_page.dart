import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../vc/otp_vc.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final controllers = List.generate(5, (_) => TextEditingController());
  final focus = List.generate(5, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in controllers) c.dispose();
    for (final f in focus) f.dispose();
    super.dispose();
  }

  String get code => controllers.map((e) => e.text).join();

  @override
  Widget build(BuildContext context) {
    final email = (ModalRoute.of(context)?.settings.arguments as String?) ?? '';
    final st = ref.watch(otpVCProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please check your email.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We have sent a code to $email',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (i) => _otpBox(i, st.error != null)),
            ),

            const SizedBox(height: 16),

            if (st.error != null) ...[
              Center(
                child: Column(
                  children: [
                    Text(
                      'Invalid Code!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please try again or resend code.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          ref.read(otpVCProvider.notifier).resend(email),
                      child: Text(
                        'Resend Code',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2AA6A0),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ] else
              const SizedBox(height: 12),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: st.loading
                    ? null
                    : () async {
                        final ok = await ref
                            .read(otpVCProvider.notifier)
                            .verify(email: email, code: code);
                        if (ok && context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            '/verify-success',
                          );
                        } else {
                          // highlight red boxes
                          setState(() {});
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
                        'Verify Now',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index, bool isError) {
    return Container(
      width: 54,
      height: 54,
      margin: const EdgeInsets.only(right: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.error : AppColors.primary,
          width: 1.4,
        ),
      ),
      child: TextField(
        controller: controllers[index],
        focusNode: focus[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 4) {
            focus[index + 1].requestFocus();
          }
          if (v.isEmpty && index > 0) {
            focus[index - 1].requestFocus();
          }
          ref.read(otpVCProvider.notifier).clearError();
        },
      ),
    );
  }
}
