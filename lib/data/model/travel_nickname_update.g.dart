// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_nickname_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelNicknameUpdate _$TravelNicknameUpdateFromJson(
  Map<String, dynamic> json,
) => TravelNicknameUpdate(
  travelId: (json['travelId'] as num).toInt(),
  travelUserId: (json['travelUserId'] as num).toInt(),
  travelNickname: json['travelNickname'] as String,
);

Map<String, dynamic> _$TravelNicknameUpdateToJson(
  TravelNicknameUpdate instance,
) => <String, dynamic>{
  'travelId': instance.travelId,
  'travelUserId': instance.travelUserId,
  'travelNickname': instance.travelNickname,
};
