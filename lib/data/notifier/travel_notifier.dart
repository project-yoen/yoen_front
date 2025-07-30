import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
import 'package:yoen_front/data/model/travel_create_response.dart';
import 'package:yoen_front/data/repository/travel_repository.dart';

final travelNotifierProvider =
    StateNotifierProvider<TravelNotifier, TravelState>((ref) {
  final repository = ref.watch(travelRepositoryProvider);
  return TravelNotifier(repository);
});

class TravelNotifier extends StateNotifier<TravelState> {
  final TravelRepository _repository;

  TravelNotifier(this._repository) : super(TravelState.initial());

  Future<void> createTravel(TravelCreateRequest request) async {
    state = state.copyWith(status: TravelStatus.loading);
    try {
      final response = await _repository.createTravel(request);
      state = state.copyWith(
        status: TravelStatus.success,
        travel: response,
      );
    } catch (e) {
      state = state.copyWith(
        status: TravelStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

enum TravelStatus { initial, loading, success, error }

class TravelState {
  final TravelStatus status;
  final TravelCreateResponse? travel;
  final String? errorMessage;

  TravelState({
    required this.status,
    this.travel,
    this.errorMessage,
  });

  factory TravelState.initial() {
    return TravelState(status: TravelStatus.initial);
  }

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
