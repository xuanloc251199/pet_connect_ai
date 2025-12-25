import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/auth_models.dart';
import 'auth_providers.dart';

class OtpState {
  final bool loading;
  final String? error;

  const OtpState({this.loading = false, this.error});
  OtpState copyWith({bool? loading, String? error}) =>
      OtpState(loading: loading ?? this.loading, error: error);
}

class OtpVC extends Notifier<OtpState> {
  @override
  OtpState build() => const OtpState();

  Future<bool> verify({required String email, required String code}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyOtp(VerifyOtpPayload(email: email, code: code));
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Invalid Code!');
      return false;
    }
  }

  Future<void> resend(String email) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resendOtp(email);
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(error: null);
}

final otpVCProvider = NotifierProvider<OtpVC, OtpState>(OtpVC.new);
