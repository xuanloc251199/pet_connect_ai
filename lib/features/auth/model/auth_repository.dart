import '../../../app/core/api_client.dart';
import '../../../app/core/token_storage.dart';
import 'auth_api.dart';
import 'auth_models.dart';

class AuthRepository {
  final AuthApi api;
  final TokenStorage tokenStorage;

  AuthRepository({required this.api, required this.tokenStorage});

  Future<String> register(RegisterPayload payload) async {
    final res = await api.register(payload);

    // backend: { success, message, data: { next: VERIFY_EMAIL, email } }
    final data = (res['data'] as Map<String, dynamic>?);
    return (data?['email'] as String?) ?? payload.email;
  }

  Future<void> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final res = await api.login(email: email, password: password);

    final data = (res['data'] as Map<String, dynamic>?);
    final token = (data?['token'] as String?) ?? '';

    if (token.isEmpty) {
      throw Exception('Missing token from API');
    }

    await tokenStorage.saveToken(token, persist: remember);
  }

  Future<bool> hasSession() async {
    final token = await tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await tokenStorage.clear();
  }

  Future<void> verifyOtp(VerifyOtpPayload payload) async {
    final tokens = await api.verifyOtp(payload);
    await tokenStorage.saveToken(tokens.accessToken);
  }

  Future<void> resendOtp(String email) => api.resendOtp(email);
}
