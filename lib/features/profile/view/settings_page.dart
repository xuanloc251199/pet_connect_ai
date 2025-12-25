import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../vc/profile_vc.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
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
    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(profileVCProvider);
    final vc = ref.read(profileVCProvider.notifier);
    final d = st.data ?? {};
    final isPrivate = (d['is_private'] ?? false) as bool;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Private account',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: isPrivate,
                  onChanged: st.loading || st.uploading
                      ? null
                      : (v) async {
                          await vc.togglePrivate(v);
                          final err = ref.read(profileVCProvider).error;
                          if (err == null) {
                            _toast(
                              context,
                              v
                                  ? 'Đã bật chế độ riêng tư'
                                  : 'Đã tắt chế độ riêng tư',
                            );
                          } else {
                            _toast(context, err);
                          }
                        },
                  activeColor: AppColors.accent,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.border),
            ),
            leading: const Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text(
              'Edit profile',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          ),

          const SizedBox(height: 12),

          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.border),
            ),
            leading: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            title: const Text(
              'Reload profile',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: st.loading ? null : () => vc.load(),
          ),

          const SizedBox(height: 12),

          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.border),
            ),
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
              ),
            ),
            onTap: st.loading || st.uploading
                ? null
                : () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}
