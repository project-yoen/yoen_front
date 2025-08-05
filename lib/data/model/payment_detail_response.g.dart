// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentDetailResponse _$PaymentDetailResponseFromJson(
  Map<String, dynamic> json,
) => PaymentDetailResponse(
  travelId: (json['travelId'] as num?)?.toInt(),
  paymentId: (json['paymentId'] as num?)?.toInt(),
  categoryId: (json['categoryId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  payerType: json['payerType'] as String?,
  payerName: json['payerName'] == null
      ? null
      : TravelUserDetailResponse.fromJson(
          json['payerName'] as Map<String, dynamic>,
        ),
  paymentMethod: json['paymentMethod'] as String?,
  paymentName: json['paymentName'] as String?,
  paymentType: json['paymentType'] as String?,
  exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
  payTime: json['payTime'] as String?,
  paymentAccount: (json['paymentAccount'] as num?)?.toInt(),
  settlements: (json['settlements'] as List<dynamic>?)
      ?.map((e) => SettlementResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => PaymentImageResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaymentDetailResponseToJson(
  PaymentDetailResponse instance,
) => <String, dynamic>{
  'travelId': instance.travelId,
  'paymentId': instance.paymentId,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'payerType': instance.payerType,
  'payerName': instance.payerName?.toJson(),
  'paymentMethod': instance.paymentMethod,
  'paymentName': instance.paymentName,
  'paymentType': instance.paymentType,
  'exchangeRate': instance.exchangeRate,
  'payTime': instance.payTime,
  'paymentAccount': instance.paymentAccount,
  'settlements': instance.settlements?.map((e) => e.toJson()).toList(),
  'images': instance.images?.map((e) => e.toJson()).toList(),
};
