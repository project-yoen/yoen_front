// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_profile_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelProfileImage _$TravelProfileImageFromJson(Map<String, dynamic> json) =>
    TravelProfileImage(
      travelId: (json['travelId'] as num).toInt(),
      recordImageId: (json['recordImageId'] as num).toInt(),
    );

Map<String, dynamic> _$TravelProfileImageToJson(TravelProfileImage instance) =>
    <String, dynamic>{
      'travelId': instance.travelId,
      'recordImageId': instance.recordImageId,
    };
