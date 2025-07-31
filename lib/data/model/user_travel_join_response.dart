import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/user_response.dart';

part 'user_travel_join_response.g.dart';

@JsonSerializable()
class UserTravelJoinResponse {
  final int travelJoinId;
  final int travelId;
  final String travelName;
  final String nation;
  final List<UserResponse> users;

  UserTravelJoinResponse({
    required this.travelJoinId,
    required this.travelId,
    required this.travelName,
    required this.nation,
    required this.users,
  });

  factory UserTravelJoinResponse.fromJson(Map<String, dynamic> json) =>
      _$UserTravelJoinResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserTravelJoinResponseToJson(this);
}
