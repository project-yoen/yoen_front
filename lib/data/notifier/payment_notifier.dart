import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import 'package:yoen_front/data/model/payment_detail_response.dart';
import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/repository/payment_repository.dart';

enum Status { initial, loading, success, error }

class PaymentState {
  final Status getStatus;
  final Status createStatus;
  final Status deleteStatus;
  final Status getDetailsStatus;
  final List<PaymentResponse> payments;
  final PaymentDetailResponse? selectedPayment;
  final String? errorMessage;

  PaymentState({
    this.getStatus = Status.initial,
    this.createStatus = Status.initial,
    this.deleteStatus = Status.initial,
    this.getDetailsStatus = Status.initial,
    this.payments = const [],
    this.selectedPayment,
    this.errorMessage,
  });

  PaymentState copyWith({
    Status? getStatus,
    Status? createStatus,
    Status? getDetailsStatus,
    Status? deleteStatus,
    List<PaymentResponse>? payments,
    PaymentDetailResponse? selectedPayment,
    String? errorMessage,
    bool? resetCreateStatus,
    bool? resetDeleteStatus,
  }) {
    return PaymentState(
      getStatus: getStatus ?? this.getStatus,
      createStatus: resetCreateStatus == true
          ? Status.initial
          : (createStatus ?? this.createStatus),
      deleteStatus: resetDeleteStatus == true
          ? Status.initial
          : (deleteStatus ?? this.deleteStatus),
      getDetailsStatus: getDetailsStatus ?? this.getDetailsStatus,
      payments: payments ?? this.payments,
      selectedPayment: selectedPayment ?? this.selectedPayment,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(PaymentState());

  Future<void> getPayments(int travelId, DateTime date) async {
    state = state.copyWith(
      getStatus: Status.loading,
      resetCreateStatus: true,
      resetDeleteStatus: true,
    );
    try {
      final dateString = date.toIso8601String();
      final payments = await _repository.getPayments(travelId, dateString);
      // payTime을 기준으로 오름차순 정렬 (오래된 것이 위로)
      payments.sort((a, b) => a.payTime.compareTo(b.payTime));
      state = state.copyWith(getStatus: Status.success, payments: payments);
    } catch (e) {
      state = state.copyWith(
        getStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  void resetAll() {
    state = PaymentState();
  }

  Future<void> createPayment(PaymentRequest request, List<File> images) async {
    state = state.copyWith(createStatus: Status.loading);
    try {
      print(request.settlementList[0].travelUsers[0].isPaid);
      await _repository.createPayment(request, images);
      state = state.copyWith(createStatus: Status.success);
    } catch (e) {
      state = state.copyWith(
        createStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> getPaymentDetails(int paymentId) async {
    state = state.copyWith(
      getDetailsStatus: Status.loading,
      resetCreateStatus: true,
    );
    try {
      final paymentDetails = await _repository.getPaymentDetails(paymentId);
      state = state.copyWith(
        getDetailsStatus: Status.success,
        selectedPayment: paymentDetails,
      );
    } catch (e) {
      state = state.copyWith(
        getDetailsStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deletePayment(int paymentId) async {
    state = state.copyWith(deleteStatus: Status.loading);
    try {
      await _repository.deletePayment(paymentId);
      final updatedPayments = state.payments
          .where((payment) => payment.paymentId != paymentId)
          .toList();
      state = state.copyWith(
        deleteStatus: Status.success,
        payments: updatedPayments,
      );
    } catch (e) {
      state = state.copyWith(
        deleteStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentRepository(apiService);
});

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
      final repository = ref.watch(paymentRepositoryProvider);
      return PaymentNotifier(repository);
    });
