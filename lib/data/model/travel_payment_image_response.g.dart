// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_payment_image_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelPaymentImageResponse _$TravelPaymentImageResponseFromJson(
  Map<String, dynamic> json,
) => TravelPaymentImageResponse(
  travelRecordImageId: (json['travelRecordImageId'] as num).toInt(),
  imageUrl: json['imageUrl'] as String,
);

Map<String, dynamic> _$TravelPaymentImageResponseToJson(
  TravelPaymentImageResponse instance,
) => <String, dynamic>{
  'travelRecordImageId': instance.travelRecordImageId,
  'imageUrl': instance.imageUrl,
};
