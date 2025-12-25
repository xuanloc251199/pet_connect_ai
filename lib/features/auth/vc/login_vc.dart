import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

class LoginState {
  final bool loading;
  final String? error;
  final bool remember;

  const LoginState({this.loading = false, this.error, this.remember = true});

  LoginState copyWith({bool? loading, String? error, bool? remember}) {
    return LoginState(
      loading: loading ?? this.loading,
      error: error,
      remember: remember ?? this.remember,
    );
  }
}

class LoginVC extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void toggleRemember(bool v) => state = state.copyWith(remember: v);

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(
        email: email,
        password: password,
        remember: state.remember,
      );
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final loginVCProvider = NotifierProvider<LoginVC, LoginState>(LoginVC.new);
