import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
import 'package:yoen_front/data/model/travel_create_response.dart';
import 'package:yoen_front/data/model/travel_profile_image.dart';
import 'package:yoen_front/data/model/travel_response.dart';
import 'package:yoen_front/data/model/travel_detail_response.dart';
import '../api/api_provider.dart';

final travelRepositoryProvider = Provider<TravelRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TravelRepository(apiService);
});

class TravelRepository {
  final ApiService _apiService;

  TravelRepository(this._apiService);

  Future<TravelCreateResponse> createTravel(TravelCreateRequest request) async {
    final apiResponse = await _apiService.createTravel(request);
    if (apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to create travel');
    }
  }

  Future<List<TravelResponse>> getTravels() async {
    final apiResponse = await _apiService.getTravels();
    if (apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to get travels');
    }
  }

  Future<TravelDetailResponse> getTravelDetail(int travelId) async {
    final apiResponse = await _apiService.getTravelDetail(travelId);
    if (apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to get travel detail');
    }
  }

  Future<String> leaveTravel(int travelId) async {
    final apiResponse = await _apiService.leaveTravel(travelId);
    if (apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to get travels');
    }
  }

  Future<String> updateImage(int travelId, int recordImageId) async {
    final request = TravelProfileImage(
      travelId: travelId,
      recordImageId: recordImageId,
    );

    final apiResponse = await _apiService.updateTravelProfileImage(request);
    if (apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.error ?? 'Failed to update travel image');
    }
  }
}
