import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest {
  final int? userId;
  final String? email;
  final String? password;
  final String? gender;
  final String? birthday;

  RegisterRequest({
    this.userId,
    required this.email,
    required this.password,
    this.gender,
    this.birthday,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
