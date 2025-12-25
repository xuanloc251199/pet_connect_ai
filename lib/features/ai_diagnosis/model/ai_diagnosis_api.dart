import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../app/core/api_client.dart';
import 'ai_diagnosis_result.dart';

class AiDiagnosisApi {
  final ApiClient client;
  AiDiagnosisApi(this.client);

  Future<AiDiagnosisResult> diagnose({
    required File imageFile,
    int? petId,
  }) async {
    final fileName = imageFile.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();

    final mime = switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };

    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
        contentType: mime,
      ),
      if (petId != null) 'pet_id': petId,
    });

    final res = await client.dio.post('/ai/diagnose', data: form);

    if (res.data is Map && res.data['success'] == true) {
      final data = (res.data['data'] as Map).cast<String, dynamic>();
      return AiDiagnosisResult.fromJson(data);
    }

    throw Exception(res.data?['message'] ?? 'AI diagnose failed');
  }
}
