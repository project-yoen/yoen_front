// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelResponse _$TravelResponseFromJson(Map<String, dynamic> json) =>
    TravelResponse(
      travelId: (json['travelId'] as num).toInt(),
      travelName: json['travelName'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$TravelResponseToJson(TravelResponse instance) =>
    <String, dynamic>{
      'travelId': instance.travelId,
      'travelName': instance.travelName,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'imageUrl': instance.imageUrl,
    };
