import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/auth_models.dart';
import '../model/auth_repository.dart';
import 'auth_providers.dart';

class OtpState {
  final bool loading;
  final String? error;

  const OtpState({this.loading = false, this.error});

  OtpState copyWith({bool? loading, String? error}) {
    return OtpState(loading: loading ?? this.loading, error: error);
  }
}

class OtpVC extends Notifier<OtpState> {
  @override
  OtpState build() => const OtpState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  String _msg(Object e) {
    final s = e.toString();
    return s.startsWith('Lỗi: ') ? s.replaceFirst('Lỗi: ', '') : s;
  }

  Future<bool> verifyOtp({required String email, required String code}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.verifyOtp(VerifyOtpPayload(email: email.trim(), code: code));
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e as Object));
      return false;
    }
  }

  Future<void> resend(String email) async {
    state = state.copyWith(error: null);
    try {
      await _repo.resendOtp(email.trim());
    } catch (e) {
      state = state.copyWith(error: _msg(e as Object));
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final otpVCProvider = NotifierProvider<OtpVC, OtpState>(OtpVC.new);
