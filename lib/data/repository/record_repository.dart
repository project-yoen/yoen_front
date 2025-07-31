import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/model/record_create_response.dart';
import 'package:http_parser/http_parser.dart';

import 'package:yoen_front/data/model/record_response.dart';

class RecordRepository {
  final ApiService _apiService;

  RecordRepository(this._apiService);

  Future<List<RecordResponse>> getRecords(int travelId, String date) async {
    final response = await _apiService.getRecords(travelId, date);
    return response.data!;
  }

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
