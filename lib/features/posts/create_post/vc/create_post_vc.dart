import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/vc/auth_providers.dart';
import '../model/create_post_api.dart';
import 'create_post_state.dart';

final createPostApiProvider = Provider<CreatePostApi>((ref) {
  // dùng watch để provider rebuild đúng khi apiClient thay đổi
  final client = ref.watch(apiClientProvider);

  // Nếu apiClientProvider của bạn là nullable (ApiClient?)
  // thì chặn luôn ở đây để khỏi crash.
  if (client == null) {
    throw StateError('ApiClient is null (not authenticated or not ready).');
  }

  return CreatePostApi(client);
});

final createPostVCProvider = NotifierProvider<CreatePostVC, CreatePostState>(
  CreatePostVC.new,
);

class CreatePostVC extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => const CreatePostState();

  Future<Map<String, dynamic>?> submit({
    required String content,
    required List<File> images,
    String privacy = 'public',
  }) async {
    if (state.loading) return null;

    // validate trước (optional)
    final trimmed = content.trim();
    final hasContent = trimmed.isNotEmpty;
    final hasImages = images.isNotEmpty;

    if (!hasContent && !hasImages) {
      state = state.copyWith(
        loading: false,
        error: 'Please add content or images.',
        success: false,
      );
      return null;
    }

    state = state.copyWith(loading: true, error: null, success: false);

    try {
      // ✅ catch được lỗi null client thay vì crash app
      final api = ref.read(createPostApiProvider);

      final data = await api.createPost(
        content: hasContent ? trimmed : null,
        images: images,
        privacy: privacy,
      );

      state = state.copyWith(loading: false, success: true, error: null);
      return data;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
        success: false,
      );
      return null;
    }
  }

  void reset() => state = const CreatePostState();
}
