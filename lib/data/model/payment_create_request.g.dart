// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentCreateRequest _$PaymentCreateRequestFromJson(
  Map<String, dynamic> json,
) => PaymentCreateRequest(
  travelId: (json['travelId'] as num).toInt(),
  travelUserId: (json['travelUserId'] as num?)?.toInt(),
  paymentName: json['paymentName'] as String,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  payerType: json['payerType'] as String,
  payTime: json['payTime'] as String,
  paymentMethod: json['paymentMethod'] as String,
  paymentType: json['paymentType'] as String,
  paymentAccount: (json['paymentAccount'] as num).toInt(),
  settlementList: (json['settlementList'] as List<dynamic>)
      .map((e) => Settlement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaymentCreateRequestToJson(
  PaymentCreateRequest instance,
) => <String, dynamic>{
  'travelId': instance.travelId,
  'travelUserId': instance.travelUserId,
  'categoryId': instance.categoryId,
  'payerType': instance.payerType,
  'payTime': instance.payTime,
  'paymentMethod': instance.paymentMethod,
  'paymentName': instance.paymentName,
  'paymentType': instance.paymentType,
  'paymentAccount': instance.paymentAccount,
  'settlementList': instance.settlementList,
};

Settlement _$SettlementFromJson(Map<String, dynamic> json) => Settlement(
  settlementName: json['settlementName'] as String,
  amount: (json['amount'] as num).toInt(),
  isPaid: json['isPaid'] as bool,
  travelUsers: (json['travelUsers'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$SettlementToJson(Settlement instance) =>
    <String, dynamic>{
      'settlementName': instance.settlementName,
      'amount': instance.amount,
      'isPaid': instance.isPaid,
      'travelUsers': instance.travelUsers,
    };
