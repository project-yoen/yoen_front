// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_payment_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementPaymentType _$SettlementPaymentTypeFromJson(
  Map<String, dynamic> json,
) => SettlementPaymentType(
  paymentType: $enumDecode(_$PaymentTypeEnumMap, json['paymentType']),
  settlementList: (json['settlementList'] as List<dynamic>)
      .map(
        (e) => SettlementResponseUserDetail.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$SettlementPaymentTypeToJson(
  SettlementPaymentType instance,
) => <String, dynamic>{
  'paymentType': _$PaymentTypeEnumMap[instance.paymentType]!,
  'settlementList': instance.settlementList,
};

const _$PaymentTypeEnumMap = {
  PaymentType.PAYMENT: 'PAYMENT',
  PaymentType.SHAREDFUND: 'SHAREDFUND',
  PaymentType.PREPAYMENT: 'PREPAYMENT',
};
