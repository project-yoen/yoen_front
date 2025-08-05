import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return PaymentNotifier(apiService);
    });

class PaymentNotifier extends StateNotifier<PaymentState> {
  final ApiService apiService;

  PaymentNotifier(this.apiService) : super(PaymentState.initial());

  Future<void> createPayment(
    PaymentCreateRequest request,
    List<File> images,
  ) async {
    state = PaymentState.loading();
    try {
      await apiService.createPayment(request, images);
      state = PaymentState.success();
    } catch (e) {
      state = PaymentState.error(e.toString());
    }
  }
}

class PaymentState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  PaymentState({
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage,
  });

  factory PaymentState.initial() {
    return PaymentState(isLoading: false, isSuccess: false);
  }

  factory PaymentState.loading() {
    return PaymentState(isLoading: true, isSuccess: false);
  }

  factory PaymentState.success() {
    return PaymentState(isLoading: false, isSuccess: true);
  }

  factory PaymentState.error(String message) {
    return PaymentState(
      isLoading: false,
      isSuccess: false,
      errorMessage: message,
    );
  }
}
