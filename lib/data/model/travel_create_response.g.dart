// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_create_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelCreateResponse _$TravelCreateResponseFromJson(
  Map<String, dynamic> json,
) => TravelCreateResponse(
  travelId: (json['travelId'] as num).toInt(),
  travelName: json['travelName'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  nation: json['nation'] as String,
  numOfPeople: (json['numOfPeople'] as num).toInt(),
  sharedFund: (json['sharedFund'] as num?)?.toInt(),
);

Map<String, dynamic> _$TravelCreateResponseToJson(
  TravelCreateResponse instance,
) => <String, dynamic>{
  'travelId': instance.travelId,
  'travelName': instance.travelName,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'nation': instance.nation,
  'numOfPeople': instance.numOfPeople,
  'sharedFund': instance.sharedFund,
};
