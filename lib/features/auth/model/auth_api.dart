import 'package:dio/dio.dart';
import '../../../app/core/api_client.dart';
import 'auth_models.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(ApiClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> register(RegisterPayload payload) async {
    final res = await _dio.post('auth/register', data: payload.toJson());
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      'auth/login',
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<AuthTokens> verifyOtp(VerifyOtpPayload payload) async {
    final res = await _dio.post(
      'auth/email/verify-otp',
      data: payload.toJson(),
    );

    final body = Map<String, dynamic>.from(res.data as Map);
    final data = body['data'];

    String? token;
    if (data is Map) token = data['token']?.toString();
    token ??= body['token']?.toString();
    token ??= body['access_token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Missing token from verify-otp response');
    }

    return AuthTokens(accessToken: token);
  }

  Future<void> resendOtp(String email) async {
    await _dio.post('auth/email/resend-otp', data: {'email': email});
  }

  Future<void> logout() async {
    await _dio.post('auth/logout');
  }

  Future<Map<String, dynamic>> fetchCategories() async {
    final res = await _dio.get('categories');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> saveInterests({
    required bool hasPet,
    required List<int> interestIds,
  }) async {
    await _dio.put(
      'user/interests',
      data: {'has_pet': hasPet, 'interest_ids': interestIds},
    );
  }
}

class AuthTokens {
  final String accessToken;
  const AuthTokens({required this.accessToken});
}
