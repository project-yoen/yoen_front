// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_result_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementResultResponse _$SettlementResultResponseFromJson(
  Map<String, dynamic> json,
) => SettlementResultResponse(
  userSettlementList: (json['userSettlementList'] as List<dynamic>)
      .map(
        (e) => SettlementResponseUserDetail.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  paymentTypeList: (json['paymentTypeList'] as List<dynamic>)
      .map((e) => SettlementPaymentType.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SettlementResultResponseToJson(
  SettlementResultResponse instance,
) => <String, dynamic>{
  'userSettlementList': instance.userSettlementList,
  'paymentTypeList': instance.paymentTypeList,
};
