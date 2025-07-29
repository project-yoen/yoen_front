// notifiers/register_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/register_request.dart';

enum RegisterStatus { idle, loading, success, error }

class RegisterState {
  final RegisterRequest data;
  final RegisterStatus status;
  final String? errorMessage;

  RegisterState({
    required this.data,
    this.status = RegisterStatus.idle,
    this.errorMessage,
  });

  RegisterState copyWith({
    RegisterRequest? data,
    RegisterStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      data: data ?? this.data,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

final registerNotifierProvider =
    NotifierProvider<RegisterNotifier, RegisterState>(() => RegisterNotifier());

class RegisterNotifier extends Notifier<RegisterState> {
  late final ApiService _api;

  @override
  RegisterState build() {
    _api = ref.read(apiServiceProvider);
    return RegisterState(
      data: RegisterRequest(
        email: '',
        password: '',
        nickname: '',
        name: '',
        birthday: null,
        gender: null,
      ),
    );
  }

  void setEmail(String email) {
    state = state.copyWith(data: state.data.copyWith(email: email));
  }

  void setName(String name) {
    state = state.copyWith(data: state.data.copyWith(name: name));
  }

  void setPassword(String password) {
    state = state.copyWith(data: state.data.copyWith(password: password));
  }

  void setNickname(String nickname) {
    state = state.copyWith(data: state.data.copyWith(nickname: nickname));
  }

  void setBirthday(String birthday) {
    state = state.copyWith(data: state.data.copyWith(birthday: birthday));
  }

  void setGender(String gender) {
    state = state.copyWith(data: state.data.copyWith(gender: gender));
  }

  Future<void> submit() async {
    state = state.copyWith(status: RegisterStatus.loading);
    try {
      await _api.register(state.data);
      state = state.copyWith(status: RegisterStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = RegisterState(
      data: RegisterRequest(
        email: '',
        password: '',
        nickname: '',
        name: '',
        birthday: null,
        gender: null,
      ),
    );
  }
}
