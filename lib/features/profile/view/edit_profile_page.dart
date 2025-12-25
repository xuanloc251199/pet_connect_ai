import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/core/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../vc/profile_vc.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _picker = ImagePicker();

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _hometown = TextEditingController();
  final _currentCity = TextEditingController();
  final _workplace = TextEditingController();
  final _relationship = TextEditingController();

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  String _mediaBase() {
    var b = AppConfig.baseUrl;
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    b = b.replaceFirst(RegExp(r'/api/v\d+$'), '');
    return b;
  }

  String _normalizeUrl(String? path) {
    if (path == null) return '';
    final p = path.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('file://')) return p;

    final base = _mediaBase();
    if (p.startsWith('/')) return '$base$p';
    return '$base/$p';
  }

  ImageProvider _provider(String? url, String fallbackAsset) {
    final u = _normalizeUrl(url);
    if (u.isEmpty) return AssetImage(fallbackAsset);
    if (u.startsWith('file://')) {
      try {
        return FileImage(File.fromUri(Uri.parse(u)));
      } catch (_) {
        return AssetImage(fallbackAsset);
      }
    }
    return NetworkImage(u);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final d = ref.read(profileVCProvider).data ?? {};
      _name.text = (d['name'] ?? '').toString();
      _username.text = (d['username'] ?? '').toString();
      _bio.text = (d['bio'] ?? '').toString();
      _hometown.text = (d['hometown'] ?? '').toString();
      _currentCity.text = (d['current_city'] ?? '').toString();
      _workplace.text = (d['workplace'] ?? '').toString();
      _relationship.text = (d['relationship_status'] ?? '').toString();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _hometown.dispose();
    _currentCity.dispose();
    _workplace.dispose();
    _relationship.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    await ref.read(profileVCProvider.notifier).uploadAvatar(File(x.path));
    final err = ref.read(profileVCProvider).error;
    if (!mounted) return;
    if (err == null) _toast('Đã cập nhật avatar!');
  }

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    await ref.read(profileVCProvider.notifier).uploadCover(File(x.path));
    final err = ref.read(profileVCProvider).error;
    if (!mounted) return;
    if (err == null) _toast('Đã cập nhật cover!');
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(profileVCProvider);
    final vc = ref.read(profileVCProvider.notifier);
    final d = st.data ?? {};

    const coverFallback = 'assets/images/demo/cover.png';
    const avatarFallback = 'assets/images/demo/avatar_1.png';

    final avatarUrl = d['avatar'] as String?;
    final coverUrl = d['cover_photo'] as String?;

    final coverProvider = _provider(coverUrl, coverFallback);
    final avatarProvider = _provider(avatarUrl, avatarFallback);

    final busy = st.loading || st.uploading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Photos block =====
            Text(
              'Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Cover
            GestureDetector(
              onTap: busy ? null : _pickCover,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Image(image: coverProvider, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        st.uploading ? 'Uploading...' : 'Change cover',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Avatar row
            Row(
              children: [
                GestureDetector(
                  onTap: busy ? null : _pickAvatar,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                          color: Colors.black.withOpacity(0.12),
                        ),
                      ],
                    ),
                    child: CircleAvatar(backgroundImage: avatarProvider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap avatar to change photo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ===== Info block =====
            Text(
              'Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            _Field(label: 'Name', controller: _name),
            const SizedBox(height: 12),
            _Field(label: 'Username', controller: _username),
            const SizedBox(height: 12),
            _Field(label: 'Bio', controller: _bio, maxLines: 3),
            const SizedBox(height: 12),
            _Field(label: 'Hometown', controller: _hometown),
            const SizedBox(height: 12),
            _Field(label: 'Current city', controller: _currentCity),
            const SizedBox(height: 12),
            _Field(label: 'Workplace', controller: _workplace),
            const SizedBox(height: 12),
            _Field(label: 'Relationship status', controller: _relationship),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: busy
                    ? null
                    : () async {
                        final payload = {
                          'name': _name.text.trim(),
                          'username': _username.text.trim(),
                          'bio': _bio.text.trim(),
                          'hometown': _hometown.text.trim(),
                          'current_city': _currentCity.text.trim(),
                          'workplace': _workplace.text.trim(),
                          'relationship_status': _relationship.text.trim(),
                        };

                        final ok = await vc.update(payload);
                        if (!mounted) return;

                        if (ok) {
                          _toast('Cập nhật hồ sơ thành công!');
                          Navigator.pop(context);
                        } else {
                          _toast(
                            st.error ?? 'Cập nhật thất bại. Vui lòng thử lại.',
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}
