import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_service.dart';
import '../api/api_provider.dart';
import '../model/user_response.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserRepository(apiService);
});

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<void> setProfileImage(File image) async {
    final apiResponse = await _apiService.setProfileImage(image);
    if (apiResponse.success == false) {
      throw Exception(apiResponse.error ?? 'Failed to set profile image');
    }
  }

  Future<UserResponse> getUserProfile() async {
    final apiResponse = await _apiService.getUserProfile();
    if (apiResponse.success == false) {
      throw Exception(apiResponse.error ?? 'Failed to get user profile');
    }
    return apiResponse.data!;
  }

  Future<UserResponse> updateUserProfile(UserResponse updatedUser) async {
    final apiResponse = await _apiService.updateUserProfile(updatedUser);
    if (apiResponse.success == false) {
      throw Exception(apiResponse.error ?? 'Failed to update user profile');
    }
    return apiResponse.data!;
  }
}
