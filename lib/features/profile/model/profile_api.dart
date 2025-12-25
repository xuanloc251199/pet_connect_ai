import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../app/core/api_client.dart';

class ProfileApi {
  final Dio _dio;
  ProfileApi(ApiClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/profile');
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    final res = await _dio.put('/profile', data: payload);
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }

  Future<Map<String, dynamic>> uploadAvatar(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    final res = await _dio.post('/profile/avatar', data: form);
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }

  Future<Map<String, dynamic>> uploadCover(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    final res = await _dio.post('/profile/cover', data: form);
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }
}
