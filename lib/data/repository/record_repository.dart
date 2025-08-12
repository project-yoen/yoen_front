import 'dart:io';

import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/model/record_create_response.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/model/record_update_request.dart';

class RecordRepository {
  final ApiService _apiService;

  RecordRepository(this._apiService);

  Future<List<RecordResponse>> getRecords(int travelId, String date) async {
    final response = await _apiService.getRecords(travelId, date);
    return response.data!;
  }

  Future<RecordCreateResponse> createRecord(
    RecordCreateRequest request,
    List<File> images,
  ) async {
    final response = await _apiService.createRecord(request, images);
    return response.data!;
  }

  Future<RecordResponse> updateRecord(
    RecordUpdateRequest request,
    List<File> images,
  ) async {
    final response = await _apiService.updateRecord(request, images);
    return response.data!;
  }

  Future<void> deleteRecord(int recordId) async {
    await _apiService.deleteRecord(recordId);
  }
}
