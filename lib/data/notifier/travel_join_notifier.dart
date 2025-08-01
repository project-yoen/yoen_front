import 'package:dio/dio.dart';
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
    } catch (e) {
      String errorMessage = '알 수 없는 오류가 발생했습니다.';
      // TODO: 잘 작동하는거 확인하긴했는데, travelUserjoinList에서 에러를 처리하는게 아직 살짝 문제가 있음

      if (e is DioException) {
        try {
          final responseData = e.response?.data;

          if (responseData is Map<String, dynamic> &&
              responseData['error'] != null) {
            errorMessage = responseData['error'];
          } else if (responseData is String) {
            // 혹시 서버가 JSON이 아닌 plain text로 보낸 경우
            errorMessage = responseData;
          }
        } catch (_) {
          // 파싱 중 오류가 나도 기본 메시지 유지
        }
      }
      state = state.copyWith(
        status: TravelJoinStatus.error,
        errorMessage: errorMessage,
      );
    } finally {
      await getTravelJoinList(travelId);
    }
  }

  Future<void> rejectTravelJoin(int travelJoinId, int travelId) async {
    state = state.copyWith(status: TravelJoinStatus.loading);
    try {
      final response = await _repository.rejectTravelJoin(travelJoinId);
      state = state.copyWith(status: TravelJoinStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: TravelJoinStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      await getTravelJoinList(travelId);
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
