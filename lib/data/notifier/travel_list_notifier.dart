import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/travel_response.dart';
import 'package:yoen_front/data/repository/travel_repository.dart';

final travelListNotifierProvider =
    StateNotifierProvider<TravelListNotifier, TravelListState>((ref) {
  final repository = ref.watch(travelRepositoryProvider);
  return TravelListNotifier(repository);
});

class TravelListNotifier extends StateNotifier<TravelListState> {
  final TravelRepository _repository;

  TravelListNotifier(this._repository) : super(TravelListState.initial());

  Future<void> fetchTravels() async {
    state = state.copyWith(status: TravelListStatus.loading);
    try {
      final travels = await _repository.getTravels();
      // startDate를 기준으로 오름차순 정렬
      travels.sort((a, b) => a.startDate.compareTo(b.startDate));
      state = state.copyWith(
        status: TravelListStatus.success,
        travels: travels,
      );
    } catch (e) {
      state = state.copyWith(
        status: TravelListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

enum TravelListStatus { initial, loading, success, error }

class TravelListState {
  final TravelListStatus status;
  final List<TravelResponse> travels;
  final String? errorMessage;

  TravelListState({
    required this.status,
    this.travels = const [],
    this.errorMessage,
  });

  factory TravelListState.initial() {
    return TravelListState(status: TravelListStatus.initial);
  }

  TravelListState copyWith({
    TravelListStatus? status,
    List<TravelResponse>? travels,
    String? errorMessage,
  }) {
    return TravelListState(
      status: status ?? this.status,
      travels: travels ?? this.travels,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
