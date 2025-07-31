// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_record_image_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelRecordImageResponse _$TravelRecordImageResponseFromJson(
  Map<String, dynamic> json,
) => TravelRecordImageResponse(
  travelRecordImageId: (json['travelRecordImageId'] as num).toInt(),
  imageUrl: json['imageUrl'] as String,
);

Map<String, dynamic> _$TravelRecordImageResponseToJson(
  TravelRecordImageResponse instance,
) => <String, dynamic>{
  'travelRecordImageId': instance.travelRecordImageId,
  'imageUrl': instance.imageUrl,
};
