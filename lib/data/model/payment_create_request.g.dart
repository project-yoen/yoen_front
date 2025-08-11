// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRequest _$PaymentRequestFromJson(Map<String, dynamic> json) =>
    PaymentRequest(
      paymentId: (json['paymentId'] as num?)?.toInt(),
      travelId: (json['travelId'] as num).toInt(),
      travelUserId: (json['travelUserId'] as num?)?.toInt(),
      paymentName: json['paymentName'] as String,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      payerType: json['payerType'] as String,
      payTime: json['payTime'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentType: json['paymentType'] as String,
      paymentAccount: (json['paymentAccount'] as num).toInt(),
      currency: json['currency'] as String,
      settlementList: (json['settlementList'] as List<dynamic>)
          .map((e) => Settlement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaymentRequestToJson(PaymentRequest instance) =>
    <String, dynamic>{
      'paymentId': instance.paymentId,
      'travelId': instance.travelId,
      'travelUserId': instance.travelUserId,
      'categoryId': instance.categoryId,
      'payerType': instance.payerType,
      'payTime': instance.payTime,
      'paymentMethod': instance.paymentMethod,
      'paymentName': instance.paymentName,
      'paymentType': instance.paymentType,
      'paymentAccount': instance.paymentAccount,
      'currency': instance.currency,
      'settlementList': instance.settlementList,
    };

Settlement _$SettlementFromJson(Map<String, dynamic> json) => Settlement(
  settlementName: json['settlementName'] as String,
  amount: (json['amount'] as num).toInt(),
  participants: (json['participants'] as List<dynamic>)
      .map((e) => SettlementParticipant.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SettlementToJson(Settlement instance) =>
    <String, dynamic>{
      'settlementName': instance.settlementName,
      'amount': instance.amount,
      'participants': instance.participants,
    };

SettlementParticipant _$SettlementParticipantFromJson(
  Map<String, dynamic> json,
) => SettlementParticipant(
  travelUserId: (json['travelUserId'] as num).toInt(),
  isPaid: json['isPaid'] as bool,
);

Map<String, dynamic> _$SettlementParticipantToJson(
  SettlementParticipant instance,
) => <String, dynamic>{
  'travelUserId': instance.travelUserId,
  'isPaid': instance.isPaid,
};
