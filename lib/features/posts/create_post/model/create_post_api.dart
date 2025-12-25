import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../../app/core/api_client.dart';

class CreatePostApi {
  final ApiClient client;
  CreatePostApi(this.client);

  Future<Map<String, dynamic>> createPost({
    String? content,
    required List<File> images,
    String privacy = 'public',
  }) async {
    final files = <MultipartFile>[];

    for (final f in images) {
      final name = f.path.split('/').last;
      final ext = name.split('.').last.toLowerCase();

      final mime = switch (ext) {
        'png' => MediaType('image', 'png'),
        'webp' => MediaType('image', 'webp'),
        _ => MediaType('image', 'jpeg'),
      };

      files.add(
        await MultipartFile.fromFile(f.path, filename: name, contentType: mime),
      );
    }

    final form = FormData.fromMap({
      if (content != null) 'content': content,
      'privacy': privacy,
      if (files.isNotEmpty) 'images[]': files, // ✅ Laravel nhận images[]
    });

    final res = await client.dio.post('posts', data: form);

    if (res.data is Map && res.data['success'] == true) {
      return (res.data['data'] as Map).cast<String, dynamic>();
    }
    throw Exception(res.data?['message'] ?? 'Create post failed');
  }
}
