

import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';

@JsonSerializable()
class UserResponse {
  final int? userId;
  final String? name;
  final String? email;
  final String? gender;
  final String? nickname;
  final String? birthday;
  final String? imageUrl;

  UserResponse({
    this.userId,
    this.name,
    required this.email,
    this.gender,
    this.nickname,
    this.birthday,
    this.imageUrl,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
}
