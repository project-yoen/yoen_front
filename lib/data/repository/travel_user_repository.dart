import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';

import '../model/travel_nickname_update.dart';

final travelUserRepositoryProvider = Provider<TravelUserRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TravelUserRepository(apiService);
});

class TravelUserRepository {
  final ApiService _apiService;

  TravelUserRepository(this._apiService);

  Future<List<TravelUserDetailResponse>> getTravelUsers(int travelId) async {
    final response = await _apiService.getTravelUsers(travelId);
    return response.data!;
  }

  Future<String> updatedTravelNickname(
    int travelId,
    int travelUserId,
    String travelNickname,
  ) async {
    TravelNicknameUpdate request = TravelNicknameUpdate(
      travelId: travelId,
      travelUserId: travelUserId,
      travelNickname: travelNickname,
    );
    final response = await _apiService.updateTravelNickname(request);
    return response.data!;
  }
}
