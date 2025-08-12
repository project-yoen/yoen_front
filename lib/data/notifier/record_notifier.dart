// lib/data/notifier/record_notifier.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/repository/record_repository.dart';
import '../model/record_update_request.dart';

enum Status { initial, loading, success, error }

class RecordState {
  final Status getStatus;
  final Status createStatus;
  final Status updateStatus;
  final Status deleteStatus;

  final List<RecordResponse> records;
  final RecordResponse? selectedRecord;

  final String? errorMessage;

  final int? lastTravelId;
  final DateTime? lastListDate;

  RecordState({
    this.getStatus = Status.initial,
    this.createStatus = Status.initial,
    this.deleteStatus = Status.initial,
    this.updateStatus = Status.initial,
    this.records = const [],
    this.selectedRecord,
    this.errorMessage,
    this.lastTravelId,
    this.lastListDate,
  });

  RecordState copyWith({
    Status? getStatus,
    Status? createStatus,
    Status? deleteStatus,
    Status? updateStatus,
    List<RecordResponse>? records,
    RecordResponse? selectedRecord,
    String? errorMessage,
    bool? resetCreateStatus,
    bool? resetDeleteStatus,
    bool? resetUpdateStatus,
    int? lastTravelId,
    DateTime? lastListDate,
  }) {
    return RecordState(
      getStatus: getStatus ?? this.getStatus,
      createStatus: resetCreateStatus == true
          ? Status.initial
          : (createStatus ?? this.createStatus),
      deleteStatus: resetDeleteStatus == true
          ? Status.initial
          : (deleteStatus ?? this.deleteStatus),
      updateStatus: resetUpdateStatus == true
          ? Status.initial
          : (updateStatus ?? this.updateStatus),
      records: records ?? this.records,
      selectedRecord: selectedRecord ?? this.selectedRecord,
      errorMessage: errorMessage ?? this.errorMessage,
      lastTravelId: lastTravelId ?? this.lastTravelId,
      lastListDate: lastListDate ?? this.lastListDate,
    );
  }
}

class RecordNotifier extends StateNotifier<RecordState> {
  final RecordRepository _repository;

  RecordNotifier(this._repository) : super(RecordState());
  // 목록 조회 후 selectedRecord 동기화 유지 (이미 있던 로직 유지/강화)
  Future<void> getRecords(int travelId, DateTime date) async {
    state = state.copyWith(
      getStatus: Status.loading,
      resetCreateStatus: true,
      resetDeleteStatus: true,
      resetUpdateStatus: true,
      lastTravelId: travelId,
      lastListDate: date,
    );
    try {
      final dateString = date.toIso8601String();
      final records = await _repository.getRecords(travelId, dateString);
      records.sort((a, b) => a.recordTime.compareTo(b.recordTime));

      // selectedRecord가 있으면 새 리스트에서 같은 ID를 찾아 매핑
      final cur = state.selectedRecord;
      RecordResponse? synced = cur;
      if (cur != null) {
        for (final r in records) {
          if (r.travelRecordId == cur.travelRecordId) {
            synced = r;
            break;
          }
        }
      }

      state = state.copyWith(
        getStatus: Status.success,
        records: records,
        selectedRecord: synced,
      );
    } catch (e) {
      state = state.copyWith(
        getStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 서버 호출 없이: 목록에서 찾아 selectedRecord 설정
  Future<void> fetchSelectedRecord(int recordId) async {
    selectRecordById(recordId);
  }

  // 인덱스로 선택
  void selectRecordByIndex(int index) {
    if (index < 0 || index >= state.records.length) {
      state = state.copyWith(selectedRecord: null);
      return;
    }
    state = state.copyWith(selectedRecord: state.records[index]);
  }

  // ID로 선택
  void selectRecordById(int recordId) {
    RecordResponse? found;
    for (final r in state.records) {
      if (r.travelRecordId == recordId) {
        found = r;
        break;
      }
    }
    state = state.copyWith(selectedRecord: found);
  }

  // 직접 설정/해제
  void setSelectedRecord(RecordResponse? rec) {
    state = state.copyWith(selectedRecord: rec);
  }

  void resetAll() {
    state = RecordState();
  }

  // 생성
  Future<void> createRecord(
    RecordCreateRequest request,
    List<File> images,
  ) async {
    state = state.copyWith(createStatus: Status.loading);
    try {
      await _repository.createRecord(request, images);
      state = state.copyWith(createStatus: Status.success);

      // 마지막 조회 조건이 있으면 목록 갱신
      final t = state.lastTravelId, d = state.lastListDate;
      if (t != null && d != null) {
        await getRecords(t, d);
      }
    } catch (e) {
      state = state.copyWith(
        createStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 업데이트 (selectedRecord와 목록 동기화)
  Future<void> updateRecord(
    RecordUpdateRequest request,
    List<File> newImages,
  ) async {
    state = state.copyWith(updateStatus: Status.loading);
    try {
      await _repository.updateRecord(request, newImages);

      final t = state.lastTravelId, d = state.lastListDate;
      if (t != null && d != null) {
        await getRecords(t, d); // 여기서 records 최신화 + selected sync 일부 수행
      }

      // 혹시 몰라 확실하게 한 번 더 선택 고정
      selectRecordById(request.travelRecordId);

      state = state.copyWith(updateStatus: Status.success);
    } catch (e) {
      state = state.copyWith(
        updateStatus: Status.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 삭제 (selectedRecord 정리)
  Future<void> deleteRecord(int recordId) async {
    state = state.copyWith(deleteStatus: Status.loading);
    try {
      await _repository.deleteRecord(recordId);

      final updatedRecords = state.records
          .where((r) => r.travelRecordId != recordId)
          .toList();

      final sel = state.selectedRecord;
      final newSelected = (sel != null && sel.travelRecordId == recordId)
          ? null
          : sel;

      state = state.copyWith(
        deleteStatus: Status.success,
        records: updatedRecords,
        selectedRecord: newSelected,
      );
    } catch (e) {
      state = state.copyWith(
        deleteStatus: Status.error,
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
