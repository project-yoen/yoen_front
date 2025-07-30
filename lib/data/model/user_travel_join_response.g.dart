// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_travel_join_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserTravelJoinResponse _$UserTravelJoinResponseFromJson(
  Map<String, dynamic> json,
) => UserTravelJoinResponse(
  travelJoinId: (json['travelJoinId'] as num).toInt(),
  travelId: (json['travelId'] as num).toInt(),
  travelName: json['travelName'] as String,
  nation: json['nation'] as String,
  users: (json['users'] as List<dynamic>)
      .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserTravelJoinResponseToJson(
  UserTravelJoinResponse instance,
) => <String, dynamic>{
  'travelJoinId': instance.travelJoinId,
  'travelId': instance.travelId,
  'travelName': instance.travelName,
  'nation': instance.nation,
  'users': instance.users,
};
