import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/core/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/view/auth_gate.dart';
import '../vc/ai_diagnosis_vc.dart';

class AiDiagnosisPage extends ConsumerStatefulWidget {
  const AiDiagnosisPage({super.key});

  @override
  ConsumerState<AiDiagnosisPage> createState() => _AiDiagnosisPageState();
}

class _AiDiagnosisPageState extends ConsumerState<AiDiagnosisPage> {
  File? _selected;

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 88);
      if (x == null) return;

      if (!mounted) return;
      setState(() => _selected = File(x.path));
      ref.read(aiDiagnosisVCProvider.notifier).clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGate(
      guestTitle: 'Bạn cần đăng nhập',
      guestDesc: 'Đăng nhập/đăng ký để dùng AI Diagnosis.',
      child: _AiDiagnosisAuthed(
        selected: _selected,
        onPick: _pick,
        onClear: () {
          setState(() => _selected = null);
          ref.read(aiDiagnosisVCProvider.notifier).clear();
        },
      ),
    );
  }
}

class _AiDiagnosisAuthed extends ConsumerWidget {
  const _AiDiagnosisAuthed({
    required this.selected,
    required this.onPick,
    required this.onClear,
  });

  final File? selected;
  final Future<void> Function(ImageSource source) onPick;
  final VoidCallback onClear;

  String _resolveResultUrl(String raw) {
    final u = raw.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final path = u.startsWith('/') ? u.substring(1) : u;
    return AppConfig.baseStorage + path;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(aiDiagnosisVCProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Diagnosis'),
        actions: [
          IconButton(
            onPressed: (st.loading) ? null : onClear,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _imageBox(selected),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: st.loading
                        ? null
                        : () => onPick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: st.loading
                        ? null
                        : () => onPick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (selected == null || st.loading)
                    ? null
                    : () => ref
                          .read(aiDiagnosisVCProvider.notifier)
                          .diagnose(selected!),
                child: st.loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Predict'),
              ),
            ),
            if (st.error != null) ...[
              const SizedBox(height: 12),
              _errorCard(st.error!),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: st.result == null
                  ? _disclaimer()
                  : _resultCard(st.result, resolveUrl: _resolveResultUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageBox(File? selected) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: selected == null
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Chọn ảnh vùng bất thường (da/lông/mắt/vết thương nhẹ)',
                textAlign: TextAlign.center,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                selected,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  Widget _disclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Kết quả chỉ mang tính tham khảo, không thay thế chẩn đoán bác sĩ thú y.',
      ),
    );
  }

  Widget _errorCard(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error),
      ),
      child: Text(msg, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _resultCard(dynamic r, {required String Function(String) resolveUrl}) {
    // r là model của bạn; mình giữ kiểu dynamic để khỏi phá project hiện tại
    final img = resolveUrl((r.imageUrl as String?) ?? '');

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (img.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  img,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  loadingBuilder: (c, w, p) {
                    if (p == null) return w;
                    return Container(
                      height: 180,
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Species: ${r.species} (${(r.speciesConfidence * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              r.diseaseGroupVi,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'Confidence: ${(r.diseaseConfidence * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 14),
            const Text('Advice', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...List.generate(
              (r.advice as List).length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• ${r.advice[i]}'),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Disclaimer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kết quả chỉ mang tính tham khảo, không thay thế chẩn đoán bác sĩ thú y.',
            ),
          ],
        ),
      ),
    );
  }
}
