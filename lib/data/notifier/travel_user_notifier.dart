import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/repository/travel_user_repository.dart';

class TravelUserNotifier
    extends StateNotifier<AsyncValue<List<TravelUserDetailResponse>>> {
  final TravelUserRepository _repository;
  final int _travelId;

  TravelUserNotifier(this._repository, this._travelId)
    : super(const AsyncValue.loading()) {
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _repository.getTravelUsers(_travelId);
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchUsers() async => await _fetchUsers();

  Future<void> updateTravelNickname(
    int travelUserId,
    String travelNickname,
  ) async {
    try {
      // 상태를 로딩으로 변경 (UI에서 로딩 표시 가능)
      state = const AsyncValue.loading();

      await _repository.updatedTravelNickname(
        _travelId,
        travelUserId,
        travelNickname,
      );

      // 변경 후 다시 목록 불러오기
      await _fetchUsers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final travelUserNotifierProvider =
    StateNotifierProvider.family<
      TravelUserNotifier,
      AsyncValue<List<TravelUserDetailResponse>>,
      int
    >((ref, travelId) {
      final repository = ref.watch(travelUserRepositoryProvider);
      return TravelUserNotifier(repository, travelId);
    });
