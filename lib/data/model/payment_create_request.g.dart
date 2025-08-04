// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentCreateRequest _$PaymentCreateRequestFromJson(
  Map<String, dynamic> json,
) => PaymentCreateRequest(
  travelId: (json['travelId'] as num).toInt(),
  title: json['title'] as String,
  content: json['content'] as String,
  recordTime: json['recordTime'] as String,
);

Map<String, dynamic> _$PaymentCreateRequestToJson(
  PaymentCreateRequest instance,
) => <String, dynamic>{
  'travelId': instance.travelId,
  'title': instance.title,
  'content': instance.content,
  'recordTime': instance.recordTime,
};
