import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';

import '../model/payment_response.dart';
import '../repository/payment_repository.dart';

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return PaymentNotifier(apiService);
    });

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _repo;

  PaymentNotifier(this._repo) : super(PaymentState.initial());

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

  Future<void> getPayments(int travelId, DateTime date) async {
    state = state.copyWith(get: Status.loading, resetCreateStatus: true);
    try {
      final dateString = date.toIso8601String();
      final records = await _repository.getRecords(travelId, dateString);
      // recordTime을 기준으로 오름차순 정렬 (오래된 것이 위로)
      records.sort((a, b) => a.recordTime.compareTo(b.recordTime));
      state = state.copyWith(getStatus: Status.success, records: records);
    } catch (e) {
      state = state.copyWith(
        getStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }
}

class PaymentState {
  final bool isLoading;
  final bool isSuccess;
  final List<PaymentResponse> records;
  final 상세페이먼트리스폰스 selectedRecord;
  final String? errorMessage;

  PaymentState({
    this.records = const [],
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

  PaymentState copyWith({
    Status? getStatus,
    Status? createStatus,
    List<RecordResponse>? records,
    String? errorMessage,
    bool? resetCreateStatus,
  }) {
    return PaymentState(
      getStatus: getStatus ?? this.getStatus,
      createStatus: resetCreateStatus == true
          ? Status.initial
          : (createStatus ?? this.createStatus),
      records: records ?? this.records,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentRepository(apiService);
});

final recordNotifierProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
      final repository = ref.watch(paymentRepositoryProvider);
      return PaymentNotifier(repository);
    });
