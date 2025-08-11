import 'package:json_annotation/json_annotation.dart';

part 'travel_user_detail_response.g.dart';

@JsonSerializable()
class TravelUserDetailResponse {
  final int travelUserId;
  final String nickName;
  final String travelNickname;
  final String gender;
  final String birthDay;
  final String? imageUrl;

  TravelUserDetailResponse({
    required this.travelUserId,
    required this.nickName,
    required this.travelNickname,
    required this.gender,
    required this.birthDay,
    this.imageUrl,
  });

  factory TravelUserDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$TravelUserDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TravelUserDetailResponseToJson(this);
}
