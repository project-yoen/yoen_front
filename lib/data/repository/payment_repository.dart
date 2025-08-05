import 'dart:io';

import 'package:yoen_front/data/model/payment_create_response.dart';

import '../api/api_service.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
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

  Future<PaymentCreateResponse> createPayment(
    PaymentCreateRequest request,
    List<File> images,
  ) async {
    final response = await _apiService.createPayment(request, images);
    return response.data!;
  }
}
