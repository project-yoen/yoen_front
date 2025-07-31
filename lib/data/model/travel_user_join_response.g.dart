// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_user_join_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelUserJoinResponse _$TravelUserJoinResponseFromJson(
  Map<String, dynamic> json,
) => TravelUserJoinResponse(
  travelJoinRequestId: (json['travelJoinRequestId'] as num).toInt(),
  gender: json['gender'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String,
);

Map<String, dynamic> _$TravelUserJoinResponseToJson(
  TravelUserJoinResponse instance,
) => <String, dynamic>{
  'travelJoinRequestId': instance.travelJoinRequestId,
  'gender': instance.gender,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
};
