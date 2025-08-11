import 'package:json_annotation/json_annotation.dart';

part 'payment_create_request.g.dart';

@JsonSerializable()
class PaymentRequest {
  final int? paymentId;
  final int travelId;
  final int? travelUserId;
  final int? categoryId;
  final String payerType;
  final String payTime;
  final String paymentMethod;
  final String paymentName;
  final String paymentType;
  final int paymentAccount;
  final String currency;
  final List<Settlement> settlementList;

  PaymentRequest({
    this.paymentId,
    required this.travelId,
    this.travelUserId,
    required this.paymentName,
    required this.categoryId,
    required this.payerType,
    required this.payTime,
    required this.paymentMethod,
    required this.paymentType,
    required this.paymentAccount,
    required this.currency,
    required this.settlementList,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentRequestToJson(this);
}

@JsonSerializable()
class Settlement {
  final String settlementName;
  final int amount;

  /// 사람 기준 정산 상태
  final List<SettlementParticipant> travelUsers;

  Settlement({
    required this.settlementName,
    required this.amount,
    required this.travelUsers,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) =>
      _$SettlementFromJson(json);
  Map<String, dynamic> toJson() => _$SettlementToJson(this);
}

@JsonSerializable()
class SettlementParticipant {
  final int travelUserId;
  final String? travelNickname;
  final bool isPaid;

  SettlementParticipant({
    required this.travelUserId,
    this.travelNickname,
    required this.isPaid,
  });

  factory SettlementParticipant.fromJson(Map<String, dynamic> json) =>
      _$SettlementParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$SettlementParticipantToJson(this);
}
