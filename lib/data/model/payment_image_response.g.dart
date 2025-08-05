// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_image_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentImageResponse _$PaymentImageResponseFromJson(
  Map<String, dynamic> json,
) => PaymentImageResponse(
  paymentImageId: (json['paymentImageId'] as num).toInt(),
  imageUrl: json['imageUrl'] as String,
);

Map<String, dynamic> _$PaymentImageResponseToJson(
  PaymentImageResponse instance,
) => <String, dynamic>{
  'paymentImageId': instance.paymentImageId,
  'imageUrl': instance.imageUrl,
};
