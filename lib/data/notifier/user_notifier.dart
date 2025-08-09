import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_provider.dart';
import '../model/register_request.dart';
import '../model/user_response.dart';
import '../repository/user_repository.dart';

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, UserResponse>(
  () => UserNotifier(),
);

// (선택) 레포지토리 프로바이더를 따로 두면 테스트/오버라이드가 쉬움
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.read(apiServiceProvider)),
);

class UserNotifier extends AsyncNotifier<UserResponse> {
  //방법 B: 아예 저장하지 말고 필요할 때마다 읽기 (추천)
  UserRepository get _repo => ref.read(userRepositoryProvider);

  @override
  Future<UserResponse> build() async {
    // 최초 로드
    return _repo.getUserProfile();
  }

  // 로그인 시 최초 유저 데이터 설정 (nullable 방지)
  void setUser(UserResponse user) {
    state = AsyncValue.data(user);
  }

  Future<void> updateImage(File image) async {
    // 로딩/에러 감싸기
    state = await AsyncValue.guard(() async {
      await _repo.setProfileImage(image);
      return _repo.getUserProfile();
    });
  }

  Future<UserResponse> updateUserProfile(UserResponse updatedUser) async {
    state = await AsyncValue.guard(() async {
      final res = await _repo.updateUserProfile(updatedUser);
      // 서버 반영 후 최신값 다시 조회(혹은 res 그대로 사용)
      // return res;
      return _repo.getUserProfile();
    });
    // state.value!는 위에서 설정됨. 필요시 반환
    return state.value!;
  }
}
