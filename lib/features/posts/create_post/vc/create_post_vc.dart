import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/vc/auth_providers.dart';
import '../model/create_post_api.dart';
import 'create_post_state.dart';

final createPostApiProvider = Provider<CreatePostApi>((ref) {
  final client = ref.read(apiClientProvider);
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
  }) async {
    state = state.copyWith(loading: true, error: null, success: false);
    try {
      final api = ref.read(createPostApiProvider);
      final data = await api.createPost(
        content: content.trim().isEmpty ? null : content.trim(),
        images: images,
      );
      state = state.copyWith(loading: false, success: true);
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
