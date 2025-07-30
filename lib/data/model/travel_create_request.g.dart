// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelCreateRequest _$TravelCreateRequestFromJson(Map<String, dynamic> json) =>
    TravelCreateRequest(
      travelName: json['travelName'] as String,
      numOfPeople: (json['numOfPeople'] as num).toInt(),
      nation: json['nation'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      destinationIds: (json['destinationIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$TravelCreateRequestToJson(
  TravelCreateRequest instance,
) => <String, dynamic>{
  'travelName': instance.travelName,
  'numOfPeople': instance.numOfPeople,
  'nation': instance.nation,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'destinationIds': instance.destinationIds,
};
