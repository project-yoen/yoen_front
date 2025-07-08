import 'package:json_annotation/json_annotation.dart';

part 'register_response.g.dart';

@JsonSerializable()
class RegisterResponse {
  final int? userId;
  final String? email;
  final String? gender;
  final String? birthday;

  RegisterResponse({
    this.userId,
    required this.email,
    this.gender,
    this.birthday,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}
