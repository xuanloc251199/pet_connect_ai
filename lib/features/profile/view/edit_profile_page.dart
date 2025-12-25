import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const avatar = 'assets/images/demo/avatar_1.png';
    const cover = 'assets/images/demo/cover_dog.jpg';

    Widget rowTitle(String title, VoidCallback onEdit) {
      return Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF2AA6FF),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onEdit,
            child: Text(
              'Edit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2AA6FF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }

    Widget divider() => const Divider(height: 20, color: AppColors.border);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Edit Profile',
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
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        children: [
          rowTitle('Profile Picture', () {}),
          const SizedBox(height: 10),
          Center(
            child: CircleAvatar(
              radius: 54,
              backgroundImage: const AssetImage(avatar),
              backgroundColor: AppColors.surface,
            ),
          ),
          divider(),

          rowTitle('Cover Photo', () {}),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(cover, height: 170, fit: BoxFit.cover),
          ),
          divider(),

          rowTitle('Bio', () {}),
          Text(
            'Proud dog parent to two energetic Golden Retrievers,\nMax and Bella. 🐾',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          divider(),

          rowTitle('Personal Information', () {}),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.location_on_outlined, text: 'Hometown'),
          _InfoRow(icon: Icons.home_outlined, text: 'Current City'),
          _InfoRow(icon: Icons.work_outline, text: 'Workplace'),
          _InfoRow(icon: Icons.favorite_border, text: 'Relationship Status'),
          divider(),

          Text(
            'Account Settings',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF6AAEAF),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.iconInactive, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
