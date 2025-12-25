import 'package:dio/dio.dart';
import '../../../app/core/token_storage.dart';
import 'auth_api.dart';
import 'auth_models.dart';

class AuthRepository {
  final AuthApi api;
  final TokenStorage tokenStorage;

  AuthRepository({required this.api, required this.tokenStorage});

  // =======================
  // Friendly error mapping
  // =======================
  String _friendlyError(Object e) {
    if (e is DioException) {
      // timeout
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Kết nối quá lâu. Vui lòng thử lại.';
      }

      // no network / DNS / socket
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối mạng. Kiểm tra Wi-Fi/4G rồi thử lại.';
      }

      final res = e.response;
      final status = res?.statusCode;

      // Prefer backend message / errors
      final data = res?.data;
      if (data is Map) {
        final body = Map<String, dynamic>.from(data);

        final msg = body['message']?.toString();
        if (msg != null && msg.trim().isNotEmpty) {
          if (status == 401) return 'Email hoặc mật khẩu không đúng.';
          return msg;
        }

        final errors = body['errors'];
        if (errors is Map) {
          for (final entry in errors.entries) {
            final v = entry.value;
            if (v is List && v.isNotEmpty) return v.first.toString();
            if (v != null) return v.toString();
          }
        }
      }

      // Map common status
      if (status == 401) return 'Email hoặc mật khẩu không đúng.';
      if (status == 403) return 'Bạn không có quyền thực hiện thao tác này.';
      if (status == 404) return 'Không tìm thấy tài nguyên yêu cầu.';
      if (status == 422) return 'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.';
      if (status != null && status >= 500) {
        return 'Hệ thống đang bận. Vui lòng thử lại sau.';
      }

      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }

    // Non-dio
    final s = e.toString();
    if (s.contains('Missing token'))
      return 'Đăng nhập thất bại. Vui lòng thử lại.';
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  // =======================
  // Auth flows
  // =======================

  Future<String> register(RegisterPayload payload) async {
    try {
      final res = await api.register(payload);
      final data = (res['data'] as Map<String, dynamic>?);
      return (data?['email'] as String?) ?? payload.email;
    } catch (e) {
      throw Exception(_friendlyError(e as Object));
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    try {
      final res = await api.login(email: email, password: password);

      final data = res['data'];
      String? token;

      if (data is Map) token = data['token']?.toString();
      token ??= res['token']?.toString();
      token ??= res['access_token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Missing token');
      }

      await tokenStorage.saveToken(token, persist: remember);
    } catch (e) {
      throw Exception(_friendlyError(e as Object));
    }
  }

  Future<void> verifyOtp(VerifyOtpPayload payload) async {
    try {
      final tokens = await api.verifyOtp(payload);
      await tokenStorage.saveToken(tokens.accessToken);
    } catch (e) {
      throw Exception(_friendlyError(e as Object));
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      await api.resendOtp(email);
    } catch (e) {
      throw Exception(_friendlyError(e as Object));
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // ignore network/logout errors
    } finally {
      await tokenStorage.clear();
    }
  }

  Future<bool> hasSession() async {
    final token = await tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }
}
