// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentUpdateRequest _$PaymentUpdateRequestFromJson(
  Map<String, dynamic> json,
) => PaymentUpdateRequest(
  paymentId: (json['paymentId'] as num).toInt(),
  travelId: (json['travelId'] as num).toInt(),
  paymentType: json['paymentType'] as String,
  paymentName: json['paymentName'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  payerType: json['payerType'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  travelUserId: (json['travelUserId'] as num?)?.toInt(),
  payTime: json['payTime'] as String?,
  paymentAccount: (json['paymentAccount'] as num).toInt(),
  currency: json['currency'] as String?,
  settlementList: (json['settlementList'] as List<dynamic>)
      .map((e) => Settlement.fromJson(e as Map<String, dynamic>))
      .toList(),
  removeImageIds: (json['removeImageIds'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$PaymentUpdateRequestToJson(
  PaymentUpdateRequest instance,
) => <String, dynamic>{
  'paymentId': instance.paymentId,
  'travelId': instance.travelId,
  'paymentType': instance.paymentType,
  'paymentName': instance.paymentName,
  'paymentMethod': instance.paymentMethod,
  'payerType': instance.payerType,
  'categoryId': instance.categoryId,
  'travelUserId': instance.travelUserId,
  'payTime': instance.payTime,
  'paymentAccount': instance.paymentAccount,
  'currency': instance.currency,
  'settlementList': instance.settlementList.map((e) => e.toJson()).toList(),
  'removeImageIds': instance.removeImageIds,
};
