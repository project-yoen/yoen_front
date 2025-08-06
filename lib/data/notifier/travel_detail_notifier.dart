import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/travel_detail_response.dart';
import 'package:yoen_front/data/repository/travel_repository.dart';

enum TravelDetailStatus { initial, loading, success, error }

class TravelDetailState {
  final TravelDetailStatus status;
  final TravelDetailResponse? travelDetail;
  final String? errorMessage;

  TravelDetailState({
    this.status = TravelDetailStatus.initial,
    this.travelDetail,
    this.errorMessage,
  });

  TravelDetailState copyWith({
    TravelDetailStatus? status,
    TravelDetailResponse? travelDetail,
    String? errorMessage,
  }) {
    return TravelDetailState(
      status: status ?? this.status,
      travelDetail: travelDetail ?? this.travelDetail,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TravelDetailNotifier extends StateNotifier<TravelDetailState> {
  final TravelRepository _repository;

  TravelDetailNotifier(this._repository) : super(TravelDetailState());

  Future<void> getTravelDetail(int travelId) async {
    state = state.copyWith(status: TravelDetailStatus.loading);
    try {
      final travelDetail = await _repository.getTravelDetail(travelId);
      state = state.copyWith(
        status: TravelDetailStatus.success,
        travelDetail: travelDetail,
      );
    } catch (e) {
      state = state.copyWith(
        status: TravelDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final travelDetailNotifierProvider =
    StateNotifierProvider<TravelDetailNotifier, TravelDetailState>((ref) {
  final repository = ref.watch(travelRepositoryProvider);
  return TravelDetailNotifier(repository);
});
