import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';

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
}
