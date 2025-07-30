import 'package:dio/dio.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/model/record_create_response.dart';

class RecordRepository {
  final ApiService _apiService;

  RecordRepository(this._apiService);

  Future<RecordCreateResponse> createRecord(
    RecordCreateRequest request,
    List<MultipartFile> images,
  ) async {
    final response = await _apiService.createRecord(request.toJson(), images);
    return response.data!;
  }
}
