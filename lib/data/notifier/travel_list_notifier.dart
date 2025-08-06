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

  void setSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void selectTravel(TravelResponse travel) {
    state = state.copyWith(
      status: TravelListStatus.success,
      selectedTravel: travel,
    );
  }

  Future<void> fetchTravels() async {
    final oldIndex = state.selectedIndex;
    state = state.copyWith(status: TravelListStatus.loading);
    try {
      final travels = await _repository.getTravels();
      // startDate를 기준으로 오름차순 정렬
      travels.sort((a, b) => a.startDate.compareTo(b.startDate));

      // 이전 인덱스가 새로운 목록에서 유효한지 확인하고, 아니면 0으로 리셋
      final newIndex =
          (travels.isNotEmpty && oldIndex < travels.length) ? oldIndex : 0;

      state = state.copyWith(
        status: TravelListStatus.success,
        travels: travels,
        selectedIndex: newIndex,
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
  final TravelResponse? selectedTravel;
  final String? errorMessage;
  final int selectedIndex;

  TravelListState({
    required this.status,
    this.travels = const [],
    this.selectedTravel,
    this.errorMessage,
    this.selectedIndex = 0,
  });

  factory TravelListState.initial() {
    return TravelListState(status: TravelListStatus.initial, selectedIndex: 0);
  }

  TravelListState copyWith({
    TravelListStatus? status,
    List<TravelResponse>? travels,
    TravelResponse? selectedTravel,
    String? errorMessage,
    int? selectedIndex,
  }) {
    return TravelListState(
      status: status ?? this.status,
      travels: travels ?? this.travels,
      selectedTravel: selectedTravel ?? this.selectedTravel,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}
