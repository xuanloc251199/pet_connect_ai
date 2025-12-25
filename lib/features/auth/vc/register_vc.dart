import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/auth_models.dart';
import 'auth_providers.dart';

class RegisterState {
  final bool loading;
  final String? error;

  const RegisterState({this.loading = false, this.error});
  RegisterState copyWith({bool? loading, String? error}) =>
      RegisterState(loading: loading ?? this.loading, error: error);
}

class RegisterVC extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  Future<String?> register(RegisterPayload payload) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final email = await repo.register(payload);
      state = state.copyWith(loading: false);
      return email;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final registerVCProvider = NotifierProvider<RegisterVC, RegisterState>(
  RegisterVC.new,
);
