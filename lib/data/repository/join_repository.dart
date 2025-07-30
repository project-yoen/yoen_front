import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/user_travel_join_response.dart';

import '../api/api_provider.dart';

final joinRepositoryProvider = Provider<JoinRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return JoinRepository(apiService);
});

class JoinRepository {
  final ApiService _apiService;

  JoinRepository(this._apiService);

  Future<List<UserTravelJoinResponse>> getUserJoinList() async {
    final apiResponse = await _apiService.getUserJoinList();
    if (apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to create join');
    }
  }

  Future<void> deleteTravelJoin(int travelJoinId) async {
    final apiResponse = await _apiService.deleteUserJoinTravel(travelJoinId);
    if (apiResponse.error != null) {
      throw Exception(apiResponse.error ?? 'Failed to create join');
    }
  }

  Future<String> joinTravelByCode(String joinCode) async {
    final apiResponse = await _apiService.joinTravelByCode(joinCode);
    if (apiResponse.success == true) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to create join');
    }
  }
}
