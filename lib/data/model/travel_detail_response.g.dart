// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelDetailResponse _$TravelDetailResponseFromJson(
  Map<String, dynamic> json,
) => TravelDetailResponse(
  numOfPeople: (json['numOfPeople'] as num).toInt(),
  numOfJoinedPeople: (json['numOfJoinedPeople'] as num).toInt(),
  nation: json['nation'] as String,
  sharedFund: (json['sharedFund'] as num).toInt(),
  travelName: json['travelName'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  travelImageUrl: json['travelImageUrl'] as String?,
);

Map<String, dynamic> _$TravelDetailResponseToJson(
  TravelDetailResponse instance,
) => <String, dynamic>{
  'numOfPeople': instance.numOfPeople,
  'numOfJoinedPeople': instance.numOfJoinedPeople,
  'nation': instance.nation,
  'sharedFund': instance.sharedFund,
  'travelName': instance.travelName,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'travelImageUrl': instance.travelImageUrl,
};
