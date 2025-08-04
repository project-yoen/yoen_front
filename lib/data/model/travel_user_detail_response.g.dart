// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_user_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelUserDetailResponse _$TravelUserDetailResponseFromJson(
  Map<String, dynamic> json,
) => TravelUserDetailResponse(
  travelUserId: (json['travelUserId'] as num).toInt(),
  nickName: json['nickName'] as String,
  travelNickName: json['travelNickName'] as String,
  gender: json['gender'] as String,
  birthDay: json['birthDay'] as String,
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$TravelUserDetailResponseToJson(
  TravelUserDetailResponse instance,
) => <String, dynamic>{
  'travelUserId': instance.travelUserId,
  'nickName': instance.nickName,
  'travelNickName': instance.travelNickName,
  'gender': instance.gender,
  'birthDay': instance.birthDay,
  'imageUrl': instance.imageUrl,
};
