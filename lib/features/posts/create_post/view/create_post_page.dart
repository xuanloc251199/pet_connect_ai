import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../vc/create_post_vc.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key, required this.onPosted});

  final VoidCallback onPosted; // để HomePage chuyển tab + refresh

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _content = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];

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

  Future<void> _submit() async {
    final st = ref.read(createPostVCProvider);
    if (st.loading) return;

    final data = await ref
        .read(createPostVCProvider.notifier)
        .submit(content: _content.text, images: _images);

    if (!mounted) return;

    if (data != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Posted successfully')));
      _content.clear();
      setState(() => _images.clear());
      ref.read(createPostVCProvider.notifier).reset();
      widget.onPosted();
    } else {
      final err = ref.read(createPostVCProvider).error ?? 'Create post failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(createPostVCProvider);
    final err = st.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _topBar(st.loading)),
            SliverToBoxAdapter(child: _composer(st.loading)),
            if (_images.isNotEmpty) SliverToBoxAdapter(child: _previewGrid()),
            if (err != null && err.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(
                    err, // ✅ không dùng err!
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool loading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
          const Text(
            'Create Post',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: loading ? null : _submit,
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
    );
  }

  Widget _composer(bool loading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _content,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write something about your pet…',
                border: InputBorder.none,
              ),
              enabled: !loading,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: loading ? null : _pickMulti,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: loading ? null : _pickCamera,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
                const Spacer(),
                Text(
                  '${_images.length} selected',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: GridView.builder(
        itemCount: _images.length,
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
                child: Image.file(_images[i], fit: BoxFit.cover),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: InkWell(
                  onTap: () => setState(() => _images.removeAt(i)),
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
            ],
          );
        },
      ),
    );
  }
}
