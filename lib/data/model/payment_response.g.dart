// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentResponse _$PaymentResponseFromJson(Map<String, dynamic> json) =>
    PaymentResponse(
      paymentId: (json['paymentId'] as num).toInt(),
      paymentName: json['paymentName'] as String,
      categoryName: json['categoryName'] as String,
      payer: json['payer'] as String?,
      payerType: json['payerType'] as String,
      payTime: json['payTime'] as String,
      paymentAccount: (json['paymentAccount'] as num).toInt(),
    );

Map<String, dynamic> _$PaymentResponseToJson(PaymentResponse instance) =>
    <String, dynamic>{
      'paymentId': instance.paymentId,
      'paymentName': instance.paymentName,
      'categoryName': instance.categoryName,
      'payer': instance.payer,
      'payerType': instance.payerType,
      'payTime': instance.payTime,
      'paymentAccount': instance.paymentAccount,
    };
