import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/login_request.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

enum LoginStatus { idle, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;

  LoginState({this.status = LoginStatus.idle, this.errorMessage});

  LoginState copyWith({LoginStatus? status, String? errorMessage}) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(
  () => LoginNotifier(),
);

class LoginNotifier extends Notifier<LoginState> {
  late final ApiService _api;

  @override
  LoginState build() {
    _api = ref.read(apiServiceProvider);
    return LoginState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: LoginStatus.loading);

    try {
      // 1. 로그인 API 호출
      final response = await _api.login(
        LoginRequest(email: email, password: password),
      );

      // 2. 로그인 성공시 토큰 저장
      if (response.data != null) {
        final storage = ref.read(secureStorageProvider);
        final accessToken = response.data!.accessToken;
        final refreshToken = response.data!.refreshToken;
        await storage.write(key: "accessToken", value: accessToken);
        await storage.write(key: "refreshToken", value: refreshToken);
        //Todo log로 변경
        print('✅ accessToken: $accessToken');
        print('✅ refreshToken: $refreshToken');

        // 3. 상태 업데이트
        state = state.copyWith(status: LoginStatus.success);
      } else {
        state = state.copyWith(
          status: LoginStatus.error,
          errorMessage: "로그인 실패",
          //Todo 로그아웃 실패 시 조건 분기하여 여러 에러 메세지 작성
        );
      }
    } catch (e) {
      // 4. 에러 처리
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = LoginState();
  }
}
