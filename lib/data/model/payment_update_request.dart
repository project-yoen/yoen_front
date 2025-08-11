// lib/data/model/payment_update_request.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/payment_create_request.dart'; // Settlement, SettlementParticipant

part 'payment_update_request.g.dart';

@JsonSerializable(explicitToJson: true)
class PaymentUpdateRequest {
  final int paymentId;
  final int travelId;
  final String paymentType;

  final String? paymentName;
  final String? paymentMethod;
  final String? payerType;
  final int? categoryId;
  final int? travelUserId;
  final String? payTime; // ISO 8601
  final int paymentAccount;
  final String? currency;

  /// ✅ create와 동일한 Settlement 구조 그대로 사용
  final List<Settlement> settlementList;

  /// ✅ 서버에 이미 있는 이미지 중 삭제할 id
  final List<int> removeImageIds;

  PaymentUpdateRequest({
    required this.paymentId,
    required this.travelId,
    required this.paymentType,
    this.paymentName,
    this.paymentMethod,
    this.payerType,
    this.categoryId,
    this.travelUserId,
    this.payTime,
    required this.paymentAccount,
    this.currency,
    required this.settlementList,
    required this.removeImageIds,
  });

  factory PaymentUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentUpdateRequestToJson(this);
}
