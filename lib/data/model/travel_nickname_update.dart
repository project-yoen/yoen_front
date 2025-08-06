import 'package:json_annotation/json_annotation.dart';

part 'travel_nickname_update.g.dart';

@JsonSerializable()
class TravelNicknameUpdate {
  final int travelId;
  final int travelUserId;
  final String travelNickname;

  TravelNicknameUpdate({
    required this.travelId,
    required this.travelUserId,
    required this.travelNickname,
  });

  factory TravelNicknameUpdate.fromJson(Map<String, dynamic> json) =>
      _$TravelNicknameUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$TravelNicknameUpdateToJson(this);
}
