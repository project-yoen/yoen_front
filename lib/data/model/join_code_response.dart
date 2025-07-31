import 'package:json_annotation/json_annotation.dart';

part 'join_code_response.g.dart';

@JsonSerializable()
class JoinCodeResponse {
  final String code;
  final String expiredAt;

  JoinCodeResponse({required this.code, required this.expiredAt});

  factory JoinCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$JoinCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JoinCodeResponseToJson(this);
}
