import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final storage = ref.read(tokenStorageProvider);
  final token = await storage.readToken();
  return token != null && token.trim().isNotEmpty;
});
