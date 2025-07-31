import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/accept_join_request.dart';
import 'package:yoen_front/data/model/join_code_response.dart';
import 'package:yoen_front/data/model/travel_user_join_response.dart';
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
      throw Exception(apiResponse.error ?? 'Failed to print join');
    }
  }

  Future<List<TravelUserJoinResponse>> getTravelJoinList(int travelId) async {
    final apiResponse = await _apiService.getTravelJoinList(travelId);
    if (apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to print join');
    }
  }

  Future<void> acceptTravelJoin(AcceptJoinRequest request) async {
    try {
      await _apiService.acceptTravelJoinRequest(request);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> rejectTravelJoin(int travelJoinId) async {
    try {
      await _apiService.rejectTravelJoinRequest(travelJoinId);
    } catch (_) {
      rethrow;
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

  Future<JoinCodeResponse> getJoinCode(int travelId) async {
    final apiResponse = await _apiService.getJoinCode(travelId);
    if (apiResponse.success == true) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to get joinCode');
    }
  }
}
