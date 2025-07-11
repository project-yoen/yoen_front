import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/register_request.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final RegisterRequest? user;
  final String accessToken;
  final String refreshToken;

  LoginResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
