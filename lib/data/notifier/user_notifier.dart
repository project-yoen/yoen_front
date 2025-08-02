import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_provider.dart';
import '../model/user_response.dart';
import '../repository/user_repository.dart';

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, UserResponse>(
  () => UserNotifier(),
);

class UserNotifier extends AsyncNotifier<UserResponse> {
  late final UserRepository _repo;

  @override
  Future<UserResponse> build() async {
    _repo = UserRepository(
      ref.read(apiServiceProvider),
    ); // apiProvider는 ApiService 제공하는 Provider
    return await _repo.getUserProfile();
  }

  // 로그인 시 최초 유저 데이터 설정
  void setUser(UserResponse user) {
    state = AsyncValue.data(user);
  }

  Future<void> updateImage(File image) async {
    await _repo.setProfileImage(image);
    state = AsyncValue.data(await _repo.getUserProfile()); // 갱신
  }
}
