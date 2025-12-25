import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../vc/create_post_vc.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _content = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];

  String _privacy = 'public'; // public | private

  @override
  void initState() {
    super.initState();

    // Show error via SnackBar only when it changes
    ref.listenManual(createPostVCProvider, (prev, next) {
      final prevErr = prev?.error;
      final nextErr = next.error;
      if (!mounted) return;
      if (nextErr != null && nextErr.isNotEmpty && nextErr != prevErr) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextErr),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickMulti() async {
    final picked = await _picker.pickMultiImage(imageQuality: 88);
    if (picked.isEmpty) return;

    setState(() {
      _images.addAll(picked.map((e) => File(e.path)));
    });
  }

  Future<void> _pickCamera() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );
    if (x == null) return;

    setState(() => _images.add(File(x.path)));
  }

  void _removeImageAt(int i) {
    setState(() => _images.removeAt(i));
  }

  bool get _canSubmit {
    final contentOk = _content.text.trim().isNotEmpty;
    final hasImages = _images.isNotEmpty;
    return contentOk || hasImages;
  }

  Future<void> _submit() async {
    final st = ref.read(createPostVCProvider);
    if (st.loading) return;

    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add content or images.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        ),
      );
      return;
    }

    final data = await ref
        .read(createPostVCProvider.notifier)
        .submit(
          content: _content.text,
          images: List<File>.from(_images),
          privacy: _privacy,
        );

    if (!mounted) return;

    if (data != null) {
      Navigator.pop(context, data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(createPostVCProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _TopBar(
                  loading: st.loading,
                  onSubmit: _submit,
                  onBack: () => Navigator.pop(context),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _ComposerCard(
                    loading: st.loading,
                    privacy: _privacy,
                    onPrivacyChanged: (v) => setState(() => _privacy = v),
                    controller: _content,
                    onPickGallery: _pickMulti,
                    onPickCamera: _pickCamera,
                    selectedCount: _images.length,
                  ),
                ),
              ),

              if (_images.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _PreviewGrid(
                      images: _images,
                      onRemove: _removeImageAt,
                      enabled: !st.loading,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.loading,
    required this.onSubmit,
    required this.onBack,
  });

  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: loading ? null : onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Create Post',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: _PostButton(loading: loading, onTap: onSubmit),
          ),
        ],
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  const _PostButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Post', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.loading,
    required this.privacy,
    required this.onPrivacyChanged,
    required this.controller,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.selectedCount,
  });

  final bool loading;
  final String privacy;
  final ValueChanged<String> onPrivacyChanged;

  final TextEditingController controller;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Privacy',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              _PrivacyDropdown(
                value: privacy,
                enabled: !loading,
                onChanged: onPrivacyChanged,
              ),
              const Spacer(),
              Text(
                '$selectedCount selected',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: controller,
            maxLines: 6,
            enabled: !loading,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
            decoration: const InputDecoration(
              hintText: 'Write something about your pet…',
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onPickGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onPickCamera,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacyDropdown extends StatelessWidget {
  const _PrivacyDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: enabled ? (v) => onChanged(v ?? 'public') : null,
          items: const [
            DropdownMenuItem(value: 'public', child: Text('Public')),
            DropdownMenuItem(value: 'private', child: Text('Private')),
          ],
        ),
      ),
    );
  }
}

class _PreviewGrid extends StatelessWidget {
  const _PreviewGrid({
    required this.images,
    required this.onRemove,
    required this.enabled,
  });

  final List<File> images;
  final void Function(int index) onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: images.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(images[i], fit: BoxFit.cover),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: IgnorePointer(
                ignoring: !enabled,
                child: InkWell(
                  onTap: () => onRemove(i),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
