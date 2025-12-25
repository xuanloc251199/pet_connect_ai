import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../vc/ai_diagnosis_vc.dart';

class AiDiagnosisPage extends ConsumerStatefulWidget {
  const AiDiagnosisPage({super.key});

  @override
  ConsumerState<AiDiagnosisPage> createState() => _AiDiagnosisPageState();
}

class _AiDiagnosisPageState extends ConsumerState<AiDiagnosisPage> {
  File? _selected;

  Future<void> _pick(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source, imageQuality: 88);
    if (x == null) return;
    setState(() => _selected = File(x.path));
    ref.read(aiDiagnosisVCProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(aiDiagnosisVCProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('AI Diagnosis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _imageBox(),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
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
                onPressed: (_selected == null || st.loading)
                    ? null
                    : () => ref
                          .read(aiDiagnosisVCProvider.notifier)
                          .diagnose(_selected!),
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
                  : _resultCard(st.result!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageBox() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: _selected == null
          ? const Text('Chọn ảnh vùng bất thường (da/lông/mắt/vết thương nhẹ)')
          : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                _selected!,
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

  Widget _resultCard(dynamic r) {
    // r là AiDiagnosisResult
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
            // Ảnh đã lưu trên backend (image_url)
            if ((r.imageUrl as String).isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  r.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
              r.advice.length,
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
