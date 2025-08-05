import 'dart:io';

import '../api/api_service.dart';
import '../model/payment_response.dart';
import '../model/record_create_request.dart';
import '../model/record_create_response.dart';

class PaymentRepository {
  final ApiService _apiService;

  PaymentRepository(this._apiService);

  Future<List<PaymentResponse>> getPayments(int travelId, String date) async {
    final response = await _apiService.getPayment(travelId, date);
    return response.data!;
  }

  Future<RecordCreateResponse> createRecord(
    RecordCreateRequest request,
    List<File> images,
  ) async {
    final response = await _apiService.createRecord(request, images);
    return response.data!;
  }
}
