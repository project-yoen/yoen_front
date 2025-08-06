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

  int setCreatedIndex(DateTime date) {
    for (int i = 0; i < state.travels.length; i++) {
      final travelDate = DateTime.parse(state.travels[i].startDate);
      if (date.isBefore(travelDate)) {
        return i; // 처음으로 더 큰 날짜를 찾으면 그 위치 반환
      }
    }
    // 전부 target보다 작으면 마지막에 추가
    return state.travels.length;
  }

  void selectTravel(TravelResponse travel) {
    state = state.copyWith(
      status: TravelListStatus.success,
      selectedTravel: travel,
    );
  }

  Future<void> fetchTravels() async {
    final oldIndex = state.selectedIndex;
    final wasInitialized = state.isInitialized;
    state = state.copyWith(status: TravelListStatus.loading);
    try {
      final travels = await _repository.getTravels();
      // startDate를 기준으로 오름차순 정렬
      travels.sort((a, b) => a.startDate.compareTo(b.startDate));

      int newIndex;
      if (!wasInitialized && travels.isNotEmpty) {
        // 첫 로드면 마지막 인덱스로
        newIndex = travels.length - 1;
      } else {
        // 첫 로드가 아니면 기존 인덱스 유지
        newIndex = (travels.isNotEmpty && oldIndex < travels.length)
            ? oldIndex
            : 0;
      }

      state = state.copyWith(
        status: TravelListStatus.success,
        travels: travels,
        selectedIndex: newIndex,
        isInitialized: true,
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
  final bool isInitialized;

  TravelListState({
    required this.status,
    this.travels = const [],
    this.selectedTravel,
    this.errorMessage,
    this.selectedIndex = 0,
    this.isInitialized = false,
  });

  factory TravelListState.initial() {
    return TravelListState(
      status: TravelListStatus.initial,
      selectedIndex: 0,
      isInitialized: false,
    );
  }

  TravelListState copyWith({
    TravelListStatus? status,
    List<TravelResponse>? travels,
    TravelResponse? selectedTravel,
    String? errorMessage,
    int? selectedIndex,
    bool? isInitialized,
  }) {
    return TravelListState(
      status: status ?? this.status,
      travels: travels ?? this.travels,
      selectedTravel: selectedTravel ?? this.selectedTravel,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
