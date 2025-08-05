// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementResponse _$SettlementResponseFromJson(Map<String, dynamic> json) =>
    SettlementResponse(
      settlementId: (json['settlementId'] as num).toInt(),
      paymentId: (json['paymentId'] as num).toInt(),
      settlementName: json['settlementName'] as String,
      amount: (json['amount'] as num).toInt(),
      isPaid: json['isPaid'] as bool,
      travelUsers: (json['travelUsers'] as List<dynamic>)
          .map(
            (e) => TravelUserDetailResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$SettlementResponseToJson(SettlementResponse instance) =>
    <String, dynamic>{
      'settlementId': instance.settlementId,
      'paymentId': instance.paymentId,
      'settlementName': instance.settlementName,
      'amount': instance.amount,
      'isPaid': instance.isPaid,
      'travelUsers': instance.travelUsers,
    };
