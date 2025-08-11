import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
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
    final oldSelectedTravelId = state.selectedTravel?.travelId;
    state = state.copyWith(status: TravelListStatus.loading);
    try {
      final travels = await _repository.getTravels();
      // startDate를 기준으로 오름차순 정렬
      travels.sort((a, b) => a.startDate.compareTo(b.startDate));

      TravelResponse? newSelectedTravel;
      int newIndex = 0;

      if (travels.isNotEmpty) {
        if (oldSelectedTravelId != null) {
          newIndex = travels.indexWhere(
            (t) => t.travelId == oldSelectedTravelId,
          );
          // 기존에 선택된 여행이 목록에 없으면 마지막 여행을 선택
          if (newIndex == -1) {
            newIndex = travels.length - 1;
          }
        } else {
          // 선택된 여행이 없었으면 마지막 여행을 선택
          newIndex = travels.length - 1;
        }
        newSelectedTravel = travels[newIndex];
      }

      state = state.copyWith(
        status: TravelListStatus.success,
        travels: travels,
        selectedIndex: newIndex,
        selectedTravel: newSelectedTravel,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: TravelListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<TravelResponse?> createAndSelectTravel(
    TravelCreateRequest request,
  ) async {
    state = state.copyWith(status: TravelListStatus.loading);
    try {
      // 1. 여행 생성 API 호출
      final newTravelResponse = await _repository.createTravel(request);
      final newTravel = TravelResponse(
        travelId: newTravelResponse.travelId,
        travelName: newTravelResponse.travelName,
        startDate: newTravelResponse.startDate,
        endDate: newTravelResponse.endDate,
        numOfPeople: newTravelResponse.numOfPeople,
        numOfJoinedPeople: newTravelResponse.numOfJoinedPeople,
        nation: newTravelResponse.nation,
        travelImageUrl: '',
      );

      // 2. 기존 목록에 새 여행을 추가하고 정렬 (Optimistic Update)
      final updatedTravels = List<TravelResponse>.from(state.travels)
        ..add(newTravel);
      updatedTravels.sort((a, b) => a.startDate.compareTo(b.startDate));

      // 3. 새로 생성된 여행의 인덱스 찾기
      final newIndex = updatedTravels.indexWhere(
        (t) => t.travelId == newTravel.travelId,
      );

      // 4. 상태 업데이트
      state = state.copyWith(
        status: TravelListStatus.success,
        travels: updatedTravels,
        selectedIndex: newIndex,
        selectedTravel: newTravel,
      );
      return newTravel;
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
        status: TravelListStatus.error,
        errorMessage: e.toString(),
      );
      return null;
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
