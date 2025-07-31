import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/repository/join_repository.dart';

import '../model/user_travel_join_response.dart';

final joinNotifierProvider = StateNotifierProvider<JoinNotifier, JoinState>((
  ref,
) {
  final repository = ref.watch(joinRepositoryProvider);
  return JoinNotifier(repository);
});

class JoinNotifier extends StateNotifier<JoinState> {
  final JoinRepository _repository;

  JoinNotifier(this._repository) : super(JoinState.initial());

  Future<void> getUserJoinList() async {
    state = state.copyWith(status: JoinStatus.loading);
    try {
      final response = await _repository.getUserJoinList();
      state = state.copyWith(status: JoinStatus.success, userJoins: response);
    } catch (e) {
      state = state.copyWith(
        status: JoinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> joinTravelByCode(String joinCode) async {
    state = state.copyWith(status: JoinStatus.loading);
    try {
      final response = await _repository.joinTravelByCode(joinCode);
      state = state.copyWith(status: JoinStatus.success, message: response);
    } catch (e) {
      state = state.copyWith(
        status: JoinStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteTravelJoin(int travelJoinId) async {
    state = state.copyWith(status: JoinStatus.loading);
    try {
      await _repository.deleteTravelJoin(travelJoinId);
      state = state.copyWith(status: JoinStatus.success);
      await getUserJoinList();
    } catch (e) {
      state = state.copyWith(
        status: JoinStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = JoinState.initial();
  }
}

enum JoinStatus { initial, loading, success, error }

class JoinState {
  final JoinStatus status;
  final List<UserTravelJoinResponse> userJoins;
  final String? message;
  final String? errorMessage;

  JoinState({
    this.status = JoinStatus.initial,
    this.userJoins = const [],
    this.message,
    this.errorMessage,
  });

  factory JoinState.initial() {
    return JoinState(status: JoinStatus.initial);
  }

  JoinState copyWith({
    JoinStatus? status,
    List<UserTravelJoinResponse>? userJoins,
    String? message,
    String? errorMessage,
  }) {
    return JoinState(
      status: status ?? this.status,
      userJoins: userJoins ?? this.userJoins,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
