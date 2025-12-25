import 'package:dio/dio.dart';
import 'app_config.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage _storage;

  ApiClient({TokenStorage? storage}) : _storage = storage ?? TokenStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          final token = await _storage.readToken();

          // log
          // ignore: avoid_print
          print('➡️ ${o.method} ${o.uri}');
          // ignore: avoid_print
          print('➡️ data: ${o.data}');
          // ignore: avoid_print
          print('➡️ token: ${token == null ? "NULL" : "HAS_TOKEN"}');

          // attach bearer token
          if (token != null && token.isNotEmpty) {
            o.headers['Authorization'] = 'Bearer $token';
          }

          return h.next(o);
        },
        onResponse: (r, h) {
          // ignore: avoid_print
          print('✅ ${r.statusCode} ${r.requestOptions.uri}');
          return h.next(r);
        },
        onError: (e, h) {
          // ignore: avoid_print
          print('❌ ERROR: ${e.response?.statusCode} ${e.response?.data}');
          return h.next(e);
        },
      ),
    );
  }
}
