import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/user_response.dart';

part 'travel_user_join_response.g.dart';

@JsonSerializable()
class TravelUserJoinResponse {
  final int travelJoinRequestId;
  final String gender;
  final String name;
  final String imageUrl;

  TravelUserJoinResponse({
    required this.travelJoinRequestId,
    required this.gender,
    required this.name,
    required this.imageUrl,
  });

  factory TravelUserJoinResponse.fromJson(Map<String, dynamic> json) =>
      _$TravelUserJoinResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TravelUserJoinResponseToJson(this);
}
