import 'dart:io';

import 'package:yoen_front/data/model/payment_create_response.dart';
import 'package:yoen_front/data/model/payment_detail_response.dart';

import '../api/api_service.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import '../model/payment_response.dart';
import '../model/payment_update_request.dart';
import '../model/record_create_request.dart';
import '../model/record_create_response.dart';

class PaymentRepository {
  final ApiService _apiService;

  PaymentRepository(this._apiService);

  Future<List<PaymentResponse>> getPayments(int travelId, String date) async {
    final response = await _apiService.getPayments(travelId, date);
    return response.data!;
  }

  Future<PaymentCreateResponse> createPayment(
    PaymentRequest request,
    List<File> images,
  ) async {
    final response = await _apiService.createPayment(request, images);
    return response.data!;
  }

  // 일단 스트링
  Future<String> updatePayment(
    PaymentUpdateRequest request,
    List<File> images,
  ) async {
    final response = await _apiService.updatePayment(request, images);
    return response.data!;
  }

  Future<void> deletePayment(int paymentId) async {
    await _apiService.deletePayment(paymentId);
  }

  Future<PaymentDetailResponse> getPaymentDetails(int paymentId) async {
    final response = await _apiService.getPaymentDetails(paymentId);
    return response.data!;
  }
}
