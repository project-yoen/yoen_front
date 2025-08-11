// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelResponse _$TravelResponseFromJson(Map<String, dynamic> json) =>
    TravelResponse(
      travelId: (json['travelId'] as num).toInt(),
      numOfPeople: (json['numOfPeople'] as num).toInt(),
      numOfJoinedPeople: (json['numOfJoinedPeople'] as num).toInt(),
      travelName: json['travelName'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      nation: json['nation'] as String,
      travelImageUrl: json['travelImageUrl'] as String?,
    );

Map<String, dynamic> _$TravelResponseToJson(TravelResponse instance) =>
    <String, dynamic>{
      'travelId': instance.travelId,
      'numOfPeople': instance.numOfPeople,
      'numOfJoinedPeople': instance.numOfJoinedPeople,
      'travelName': instance.travelName,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'nation': instance.nation,
      'travelImageUrl': instance.travelImageUrl,
    };
