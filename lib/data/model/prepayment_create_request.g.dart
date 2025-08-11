// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepayment_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrepaymentCreateRequest _$PrepaymentCreateRequestFromJson(
  Map<String, dynamic> json,
) => PrepaymentCreateRequest(
  travelId: (json['travelId'] as num).toInt(),
  categoryId: (json['categoryId'] as num).toInt(),
  payerTravelUserId: (json['payerTravelUserId'] as num).toInt(),
  paymentName: json['paymentName'] as String,
  paymentAccount: (json['paymentAccount'] as num).toInt(),
  currency: json['currency'] as String,
  settlementList: (json['settlementList'] as List<dynamic>)
      .map(
        (e) =>
            SettlementParticipantRequestDto.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$PrepaymentCreateRequestToJson(
  PrepaymentCreateRequest instance,
) => <String, dynamic>{
  'travelId': instance.travelId,
  'categoryId': instance.categoryId,
  'payerTravelUserId': instance.payerTravelUserId,
  'paymentName': instance.paymentName,
  'paymentAccount': instance.paymentAccount,
  'currency': instance.currency,
  'settlementList': instance.settlementList,
};

SettlementParticipantRequestDto _$SettlementParticipantRequestDtoFromJson(
  Map<String, dynamic> json,
) => SettlementParticipantRequestDto(
  travelUserId: (json['travelUserId'] as num).toInt(),
  isPaid: json['isPaid'] as bool,
);

Map<String, dynamic> _$SettlementParticipantRequestDtoToJson(
  SettlementParticipantRequestDto instance,
) => <String, dynamic>{
  'travelUserId': instance.travelUserId,
  'isPaid': instance.isPaid,
};
