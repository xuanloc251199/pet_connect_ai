import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/vc/auth_providers.dart';
import '../model/posts_api.dart';

final postsApiProvider = Provider<PostsApi>((ref) {
  final client = ref.read(apiClientProvider);
  return PostsApi(client);
});
