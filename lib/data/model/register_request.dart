import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest {
  final int? userId;
  final String? email;
  final String? password;
  final String? nickname;
  final String? gender;
  final String? birthday;

  RegisterRequest({
    this.userId,
    required this.email,
    required this.password,
    this.nickname,
    this.gender,
    this.birthday,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  RegisterRequest copyWith({
    String? email,
    String? password,
    String? nickname,
    String? birthday,
    String? gender,
  }) {
    return RegisterRequest(
      email: email ?? this.email,
      password: password ?? this.password,
      nickname: nickname ?? this.nickname,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
    );
  }
}
