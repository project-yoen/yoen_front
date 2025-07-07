import 'package:json_annotation/json_annotation.dart';

part 'user_request.g.dart';

@JsonSerializable()
class UserRequest {
  final int? userId;
  final String? email;
  final String? password;
  final String? gender;
  final String? birthday;

  UserRequest({
    this.userId,
    required this.email,
    required this.password,
    this.gender,
    this.birthday,
  });

  factory UserRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserRequestToJson(this);
}
