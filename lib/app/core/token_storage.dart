import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccessToken = 'access_token';
  final _storage = const FlutterSecureStorage();

  String? _memoryToken;

  Future<void> saveToken(String token, {bool persist = true}) async {
    _memoryToken = token;

    if (persist) {
      await _storage.write(key: _kAccessToken, value: token);
    } else {
      await _storage.delete(key: _kAccessToken);
    }
  }

  Future<String?> readToken() async {
    if (_memoryToken != null) return _memoryToken;
    final t = await _storage.read(key: _kAccessToken);
    _memoryToken = t;
    return t;
  }

  Future<void> clear() async {
    _memoryToken = null;
    await _storage.delete(key: _kAccessToken);
  }
}
