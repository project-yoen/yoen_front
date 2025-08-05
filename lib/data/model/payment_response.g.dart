// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentResponse _$PaymentResponseFromJson(Map<String, dynamic> json) =>
    PaymentResponse(
      paymentId: (json['paymentId'] as num).toInt(),
      paymentName: json['paymentName'] as String,
      categoryId: (json['categoryId'] as num).toInt(),
      payerType: json['payerType'] as String,
      payTime: json['payTime'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentType: json['paymentType'] as String,
      paymentAccount: (json['paymentAccount'] as num).toInt(),
    );

Map<String, dynamic> _$PaymentResponseToJson(PaymentResponse instance) =>
    <String, dynamic>{
      'paymentId': instance.paymentId,
      'paymentName': instance.paymentName,
      'categoryId': instance.categoryId,
      'payerType': instance.payerType,
      'payTime': instance.payTime,
      'paymentMethod': instance.paymentMethod,
      'paymentType': instance.paymentType,
      'paymentAccount': instance.paymentAccount,
    };
