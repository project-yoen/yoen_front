import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/repository/travel_user_repository.dart';

final travelUserProvider =
    FutureProvider.family<List<TravelUserDetailResponse>, int>((ref, travelId) async {
  final repository = ref.watch(travelUserRepositoryProvider);
  return await repository.getTravelUsers(travelId);
});
