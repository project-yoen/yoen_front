import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/repository/record_repository.dart';

enum RecordStatus { initial, loading, success, error }

class RecordState {
  final RecordStatus status;
  final String? errorMessage;

  RecordState({this.status = RecordStatus.initial, this.errorMessage});
}

class RecordNotifier extends StateNotifier<RecordState> {
  final RecordRepository _repository;

  RecordNotifier(this._repository) : super(RecordState());

  Future<void> createRecord(
    RecordCreateRequest request,
    List<MultipartFile> images,
  ) async {
    state = RecordState(status: RecordStatus.loading);
    try {
      await _repository.createRecord(request, images);
      state = RecordState(status: RecordStatus.success);
    } catch (e) {
      state = RecordState(
        status: RecordStatus.error,
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
