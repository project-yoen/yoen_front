import 'package:json_annotation/json_annotation.dart';

part 'payment_create_request.g.dart';

@JsonSerializable()
class PaymentCreateRequest {
  final int travelId;
  final int? travelUserId;
  final int categoryId;
  final String payerType;
  final String payTime;
  final String paymentMethod;
  final String paymentName;
  final String paymentType;
  final int paymentAccount;
  final List<Settlement> settlementList;

  PaymentCreateRequest({
    required this.travelId,
    this.travelUserId,
    required this.paymentName,
    required this.categoryId,
    required this.payerType,
    required this.payTime,
    required this.paymentMethod,
    required this.paymentType,
    required this.paymentAccount,
    required this.settlementList,
  });

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentCreateRequestToJson(this);
}

@JsonSerializable()
class Settlement {
  final String settlementName;
  final int amount;
  final bool isPaid;
  final List<int> travelUsers;

  Settlement({
    required this.settlementName,
    required this.amount,
    required this.isPaid,
    required this.travelUsers,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) =>
      _$SettlementFromJson(json);
  Map<String, dynamic> toJson() => _$SettlementToJson(this);
}
