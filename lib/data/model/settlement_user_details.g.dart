// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_user_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementUserDetails _$SettlementUserDetailsFromJson(
  Map<String, dynamic> json,
) => SettlementUserDetails(
  senderNickname: json['senderNickname'] as String,
  paymentId: (json['paymentId'] as num?)?.toInt(),
  paymentName: json['paymentName'] as String?,
  settlementName: json['settlementName'] as String?,
  amount: (json['amount'] as num).toInt(),
  isPaid: json['isPaid'] as bool?,
  payTime: json['payTime'] as String?,
);

Map<String, dynamic> _$SettlementUserDetailsToJson(
  SettlementUserDetails instance,
) => <String, dynamic>{
  'senderNickname': instance.senderNickname,
  'paymentId': instance.paymentId,
  'paymentName': instance.paymentName,
  'settlementName': instance.settlementName,
  'amount': instance.amount,
  'isPaid': instance.isPaid,
  'payTime': instance.payTime,
};
