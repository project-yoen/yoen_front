import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
import 'package:yoen_front/data/model/travel_create_response.dart';
import 'package:yoen_front/data/repository/travel_repository.dart';

// 여행 생성 과정의 상태를 관리
class TravelState {
  final TravelStatus status;
  final TravelCreateResponse? travel;
  final String? errorMessage;

  TravelState({required this.status, this.travel, this.errorMessage});

  factory TravelState.initial() => TravelState(status: TravelStatus.initial);

  TravelState copyWith({
    TravelStatus? status,
    TravelCreateResponse? travel,
    String? errorMessage,
  }) {
    return TravelState(
      status: status ?? this.status,
      travel: travel ?? this.travel,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum TravelStatus { initial, loading, success, error }

class TravelNotifier extends StateNotifier<TravelState> {
  final TravelRepository _repository;

  TravelNotifier(this._repository) : super(TravelState.initial());

  Future<void> createTravel(TravelCreateRequest request) async {
    state = state.copyWith(status: TravelStatus.loading);
    try {
      final response = await _repository.createTravel(request);
      state = state.copyWith(status: TravelStatus.success, travel: response);
    } catch (e) {
      state = state.copyWith(
        status: TravelStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> leaveTravel(int travelId) async {
    state = state.copyWith(status: TravelStatus.loading);
    try {
      final response = await _repository.leaveTravel(travelId);
      state = state.copyWith(status: TravelStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: TravelStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateImageExists(int travelId, int recordImageId) async {
    state = state.copyWith(status: TravelStatus.loading);
    try {
      final response = await _repository.updateImageExists(
        travelId,
        recordImageId,
      );
      state = state.copyWith(status: TravelStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: TravelStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateImageNew(int travelId, File image) async {
    state = state.copyWith(status: TravelStatus.loading);
    try {
      final response = await _repository.updateImageNew(travelId, image);
      state = state.copyWith(status: TravelStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: TravelStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final travelRepositoryProvider = Provider<TravelRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TravelRepository(apiService);
});

final travelNotifierProvider =
    StateNotifierProvider<TravelNotifier, TravelState>((ref) {
      final repository = ref.watch(travelRepositoryProvider);
      return TravelNotifier(repository);
    });
