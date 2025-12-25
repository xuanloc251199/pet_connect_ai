import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool privateAccount = false;
  bool pushNoti = true;
  bool promotions = false;
  bool appUpdates = true;

  @override
  Widget build(BuildContext context) {
    Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        t,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: const Color(0xFF2AA6FF),
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        children: [
          // Search
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    'Search',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.search, color: AppColors.textMuted),
              ],
            ),
          ),

          sectionTitle('Account Settings'),
          _SettingsRow(
            icon: Icons.person_outline,
            title: 'Account Details',
            onTap: () {},
          ),
          _SettingsRow(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {},
          ),
          _SettingsRow(
            icon: Icons.shield_outlined,
            title: 'Security',
            onTap: () {},
          ),

          sectionTitle('Privacy Settings'),
          _SettingsSwitchRow(
            icon: Icons.remove_red_eye_outlined,
            title: 'Private Account',
            value: privateAccount,
            onChanged: (v) => setState(() => privateAccount = v),
          ),
          _SettingsRow(
            icon: Icons.ios_share_outlined,
            title: 'Data Sharing Preferences',
            onTap: () {},
          ),
          _SettingsRow(
            icon: Icons.block_outlined,
            title: 'Blocked Users',
            onTap: () {},
          ),

          sectionTitle('Notification Settings'),
          _SettingsSwitchRow(
            icon: Icons.notifications_none_outlined,
            title: 'Push Notifications',
            value: pushNoti,
            onChanged: (v) => setState(() => pushNoti = v),
            activeColor: AppColors.accent,
          ),
          _SettingsSwitchRow(
            icon: Icons.star_border,
            title: 'Promotions',
            value: promotions,
            onChanged: (v) => setState(() => promotions = v),
            activeColor: AppColors.accent,
          ),
          _SettingsSwitchRow(
            icon: Icons.system_update_alt_outlined,
            title: 'App Updates',
            value: appUpdates,
            onChanged: (v) => setState(() => appUpdates = v),
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: activeColor),
        ],
      ),
    );
  }
}
