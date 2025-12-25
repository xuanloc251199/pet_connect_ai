import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'token_storage.dart';

class AuthSessionState {
  final bool initialized;
  final bool isLoggedIn;

  const AuthSessionState({required this.initialized, required this.isLoggedIn});

  AuthSessionState copyWith({bool? initialized, bool? isLoggedIn}) {
    return AuthSessionState(
      initialized: initialized ?? this.initialized,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  static const initial = AuthSessionState(
    initialized: false,
    isLoggedIn: false,
  );
}

class AuthSessionController extends StateNotifier<AuthSessionState> {
  AuthSessionController(this._storage) : super(AuthSessionState.initial) {
    refresh();
  }

  final TokenStorage _storage;

  Future<void> refresh() async {
    final token = await _storage.readToken();
    final hasToken = token != null && token.trim().isNotEmpty;
    state = AuthSessionState(initialized: true, isLoggedIn: hasToken);
  }

  /// Call this after login success
  Future<void> setLoggedIn() async {
    state = state.copyWith(isLoggedIn: true, initialized: true);
  }

  /// Call this after logout success
  Future<void> setLoggedOut() async {
    state = state.copyWith(isLoggedIn: false, initialized: true);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authSessionProvider =
    StateNotifierProvider<AuthSessionController, AuthSessionState>((ref) {
      return AuthSessionController(ref.read(tokenStorageProvider));
    });
