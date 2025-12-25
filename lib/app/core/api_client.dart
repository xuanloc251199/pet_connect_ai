import 'package:dio/dio.dart';
import 'app_config.dart';
import 'token_storage.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiClient {
  late final Dio dio;

  final TokenStorage _tokenStorage;
  final UnauthorizedHandler? onUnauthorized;

  ApiClient({TokenStorage? tokenStorage, this.onUnauthorized})
    : _tokenStorage = tokenStorage ?? TokenStorage() {
    final baseUrl = AppConfig.baseUrl;

    if (baseUrl.isEmpty) {
      throw StateError('AppConfig.baseUrl is empty. Please set baseUrl.');
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            o.headers['Authorization'] = 'Bearer $token';
          }
          h.next(o);
        },
        onError: (e, h) async {
          final status = e.response?.statusCode;
          if (status == 401) {
            await _tokenStorage.clear();

            await onUnauthorized?.call();
          }
          h.next(e);
        },
      ),
    );
  }
}
