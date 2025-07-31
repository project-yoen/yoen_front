import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/model/record_create_response.dart';
import 'package:http_parser/http_parser.dart';

class RecordRepository {
  final ApiService _apiService;

  RecordRepository(this._apiService);

  Future<RecordCreateResponse> createRecord(
    RecordCreateRequest request,
    List<MultipartFile> images,
  ) async {
    final jsonString = jsonEncode(request.toJson());

    final formData = FormData.fromMap({
      'dto': MultipartFile.fromString(
        jsonString,
        contentType: MediaType('application', 'json'),
        filename: 'dto.json',
      ),
      'images': images,
    });

    final response = await _apiService.createRecord(formData);
    return response.data!;
  }
}
