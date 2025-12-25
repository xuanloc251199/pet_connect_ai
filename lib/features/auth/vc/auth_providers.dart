import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/core/api_client.dart';
import '../../../app/core/token_storage.dart';
import '../model/auth_api.dart';
import '../model/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(storage: ref.read(tokenStorageProvider));
});

final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.read(apiClientProvider);
  return AuthApi(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.read(authApiProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});
