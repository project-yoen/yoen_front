import 'dart:io';

import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/repository/record_repository.dart';

enum Status { initial, loading, success, error }

class RecordState {
  final Status getStatus;
  final Status createStatus;
  final List<RecordResponse> records;
  final String? errorMessage;

  RecordState({
    this.getStatus = Status.initial,
    this.createStatus = Status.initial,
    this.records = const [],
    this.errorMessage,
  });

  RecordState copyWith({
    Status? getStatus,
    Status? createStatus,
    List<RecordResponse>? records,
    String? errorMessage,
    bool? resetCreateStatus,
  }) {
    return RecordState(
      getStatus: getStatus ?? this.getStatus,
      createStatus: resetCreateStatus == true
          ? Status.initial
          : (createStatus ?? this.createStatus),
      records: records ?? this.records,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RecordNotifier extends StateNotifier<RecordState> {
  final RecordRepository _repository;

  RecordNotifier(this._repository) : super(RecordState());

  Future<void> getRecords(int travelId, DateTime date) async {
    state = state.copyWith(getStatus: Status.loading, resetCreateStatus: true);
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

  void resetAll() {
    state = RecordState();
  }

  Future<void> createRecord(
    RecordCreateRequest request,
    List<File> images,
  ) async {
    state = state.copyWith(createStatus: Status.loading);
    try {
      await _repository.createRecord(request, images);
      state = state.copyWith(createStatus: Status.success);
    } catch (e) {
      state = state.copyWith(
        createStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RecordRepository(apiService);
});

final recordNotifierProvider =
    StateNotifierProvider<RecordNotifier, RecordState>((ref) {
      final repository = ref.watch(recordRepositoryProvider);
      return RecordNotifier(repository);
    });
