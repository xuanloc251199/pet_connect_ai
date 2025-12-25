import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../app/core/api_client.dart';

class ProfileApi {
  final Dio _dio;
  ProfileApi(ApiClient client) : _dio = client.dio;

  // GET /api/v1/profile
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('profile');
    final body = Map<String, dynamic>.from(res.data as Map);
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  // PUT /api/v1/profile
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    final res = await _dio.put('profile', data: payload);
    final body = Map<String, dynamic>.from(res.data as Map);
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  // POST /api/v1/profile/avatar
  Future<Map<String, dynamic>> uploadAvatar(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final res = await _dio.post('profile/avatar', data: form);
    final body = Map<String, dynamic>.from(res.data as Map);
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  // POST /api/v1/profile/cover
  Future<Map<String, dynamic>> uploadCover(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final res = await _dio.post('profile/cover', data: form);
    final body = Map<String, dynamic>.from(res.data as Map);
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> fetchMyPosts({
    int page = 1,
    int perPage = 30,
  }) async {
    final res = await _dio.get(
      'profile/posts',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
