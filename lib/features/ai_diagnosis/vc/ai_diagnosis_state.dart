import '../model/ai_diagnosis_result.dart';

class AiDiagnosisState {
  final bool loading;
  final String? error;
  final AiDiagnosisResult? result;

  const AiDiagnosisState({this.loading = false, this.error, this.result});

  AiDiagnosisState copyWith({
    bool? loading,
    String? error,
    AiDiagnosisResult? result,
  }) {
    return AiDiagnosisState(
      loading: loading ?? this.loading,
      error: error,
      result: result ?? this.result,
    );
  }
}
