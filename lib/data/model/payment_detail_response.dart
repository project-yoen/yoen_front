import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/payment_image_response.dart';
import 'package:yoen_front/data/model/settlement_response.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';

part 'payment_detail_response.g.dart';

@JsonSerializable(explicitToJson: true)
class PaymentDetailResponse {
  final int? travelId;
  final int? paymentId;
  final int? categoryId;
  final String? categoryName;

  final String? payerType;
  final TravelUserDetailResponse? payerName;

  final String? paymentMethod;
  final String? paymentName;
  final String? paymentType;

  final double? exchangeRate;
  final String? payTime;

  final int? paymentAccount;
  final String? currency;
  final List<SettlementResponse>? settlements;
  final List<PaymentImageResponse>? images;

  PaymentDetailResponse({
    this.travelId,
    this.paymentId,
    this.categoryId,
    this.categoryName,
    this.payerType,
    this.payerName,
    this.paymentMethod,
    this.paymentName,
    this.paymentType,
    this.exchangeRate,
    this.payTime,
    this.paymentAccount,
    this.currency,
    this.settlements,
    this.images,
  });

  factory PaymentDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDetailResponseToJson(this);
}
