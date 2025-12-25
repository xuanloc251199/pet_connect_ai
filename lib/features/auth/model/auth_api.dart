import 'package:dio/dio.dart';
import '../../../app/core/api_client.dart';
import 'auth_models.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(ApiClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> register(RegisterPayload payload) async {
    final res = await _dio.post('/auth/register', data: payload.toJson());
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<AuthTokens> verifyOtp(VerifyOtpPayload payload) async {
    final res = await _dio.post(
      '/auth/email/verify-otp',
      data: payload.toJson(),
    );
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;

    final token =
        (data?['token'] ?? body['token'] ?? body['access_token']) as String;

    return AuthTokens(accessToken: token);
  }

  Future<void> resendOtp(String email) async {
    await _dio.post('/auth/email/resend-otp', data: {'email': email});
  }

  Future<Map<String, dynamic>> fetchCategories() async {
    final res = await _dio.get('/categories');
    return res.data as Map<String, dynamic>;
  }

  Future<void> saveInterests({
    required bool hasPet,
    required List<int> interestIds,
    required String accessToken,
  }) async {
    await _dio.put(
      '/user/interests',
      data: {'has_pet': hasPet, 'interest_ids': interestIds},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }
}
