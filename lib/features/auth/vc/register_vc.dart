import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/auth_models.dart';
import '../model/auth_repository.dart';
import 'auth_providers.dart';

class RegisterState {
  final bool loading;
  final String? emailForOtp;
  final String? error;

  const RegisterState({this.loading = false, this.emailForOtp, this.error});

  RegisterState copyWith({bool? loading, String? emailForOtp, String? error}) {
    return RegisterState(
      loading: loading ?? this.loading,
      emailForOtp: emailForOtp ?? this.emailForOtp,
      error: error,
    );
  }
}

class RegisterVC extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  String _msg(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.replaceFirst('Exception: ', '') : s;
  }

  Future<bool> register(RegisterPayload payload) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final email = await _repo.register(payload);
      state = state.copyWith(loading: false, emailForOtp: email);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e as Object));
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final registerVCProvider = NotifierProvider<RegisterVC, RegisterState>(
  RegisterVC.new,
);
