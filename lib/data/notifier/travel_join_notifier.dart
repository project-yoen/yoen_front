import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/accept_join_request.dart';
import 'package:yoen_front/data/model/join_code_response.dart';
import 'package:yoen_front/data/model/travel_user_join_response.dart';
import 'package:yoen_front/data/repository/join_repository.dart';

final travelJoinNotifierProvider =
    StateNotifierProvider<TravelJoinNotifier, TravelJoinState>((ref) {
      final repository = ref.watch(joinRepositoryProvider);
      return TravelJoinNotifier(repository);
    });

class TravelJoinNotifier extends StateNotifier<TravelJoinState> {
  final JoinRepository _repository;

  TravelJoinNotifier(this._repository) : super(TravelJoinState.initial());

  Future<void> getTravelJoinList(int travelId) async {
    state = state.copyWith(status: TravelJoinStatus.loading);
    try {
      final response = await _repository.getTravelJoinList(travelId);
      state = state.copyWith(
        status: TravelJoinStatus.success,
        userJoins: response,
      );
    } catch (e) {
      state = state.copyWith(
        status: TravelJoinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> getTravelCode(int travelId) async {
    state = state.copyWith(status: TravelJoinStatus.loading);
    try {
      final response = await _repository.getJoinCode(travelId);
      state = state.copyWith(
        status: TravelJoinStatus.success,
        joinCode: response,
      );
    } catch (e) {
      state = state.copyWith(
        status: TravelJoinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> acceptTravelJoin(
    int travelJoinId,
    String role,
    int travelId,
  ) async {
    state = state.copyWith(status: TravelJoinStatus.loading);
    try {
      AcceptJoinRequest request = AcceptJoinRequest(
        travelJoinRequestId: travelJoinId,
        role: role,
      );
      final response = await _repository.acceptTravelJoin(request);
      state = state.copyWith(status: TravelJoinStatus.success);
      await getTravelJoinList(travelId);
    } catch (e) {
      state = state.copyWith(
        status: TravelJoinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> rejectTravelJoin(int travelJoinId, int travelId) async {
    state = state.copyWith(status: TravelJoinStatus.loading);
    try {
      final response = await _repository.rejectTravelJoin(travelJoinId);
      state = state.copyWith(status: TravelJoinStatus.success);
      await getTravelJoinList(travelId);
    } catch (e) {
      state = state.copyWith(
        status: TravelJoinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = TravelJoinState.initial();
  }
}

enum TravelJoinStatus { initial, loading, success, error }

class TravelJoinState {
  final TravelJoinStatus status;
  final List<TravelUserJoinResponse> userJoins;
  final JoinCodeResponse? joinCode;
  final String? errorMessage;

  TravelJoinState({
    this.status = TravelJoinStatus.initial,
    this.userJoins = const [],
    this.errorMessage,
    this.joinCode,
  });

  factory TravelJoinState.initial() {
    return TravelJoinState(status: TravelJoinStatus.initial);
  }

  TravelJoinState copyWith({
    TravelJoinStatus? status,
    List<TravelUserJoinResponse>? userJoins,
    JoinCodeResponse? joinCode,
    String? errorMessage,
  }) {
    return TravelJoinState(
      status: status ?? this.status,
      userJoins: userJoins ?? this.userJoins,
      joinCode: joinCode ?? this.joinCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
