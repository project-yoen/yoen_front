// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_payment_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementPaymentType _$SettlementPaymentTypeFromJson(
  Map<String, dynamic> json,
) => SettlementPaymentType(
  paymentType: json['paymentType'] as String,
  settlementList: (json['settlementList'] as List<dynamic>)
      .map(
        (e) => SettlementResponseUserDetail.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$SettlementPaymentTypeToJson(
  SettlementPaymentType instance,
) => <String, dynamic>{
  'paymentType': instance.paymentType,
  'settlementList': instance.settlementList,
};
