import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/vc/auth_providers.dart';
import '../model/ai_diagnosis_api.dart';
import 'ai_diagnosis_state.dart';

final aiDiagnosisApiProvider = Provider<AiDiagnosisApi>((ref) {
  final client = ref.read(apiClientProvider);
  return AiDiagnosisApi(client);
});

final aiDiagnosisVCProvider = NotifierProvider<AiDiagnosisVC, AiDiagnosisState>(
  AiDiagnosisVC.new,
);

class AiDiagnosisVC extends Notifier<AiDiagnosisState> {
  @override
  AiDiagnosisState build() => const AiDiagnosisState();

  Future<void> diagnose(File file, {int? petId}) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final api = ref.read(aiDiagnosisApiProvider);
      final result = await api.diagnose(imageFile: file, petId: petId);
      state = state.copyWith(loading: false, result: result);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void clear() => state = const AiDiagnosisState();
}
