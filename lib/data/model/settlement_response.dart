import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';

part 'settlement_response.g.dart';

@JsonSerializable()
class SettlementResponse {
  final int settlementId;
  final int paymentId;
  final String settlementName;
  final int amount;
  final bool isPaid;
  final List<SettlementParticipant> travelUsers;

  SettlementResponse({
    required this.settlementId,
    required this.paymentId,
    required this.settlementName,
    required this.amount,
    required this.isPaid,
    required this.travelUsers,
  });

  factory SettlementResponse.fromJson(Map<String, dynamic> json) =>
      _$SettlementResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementResponseToJson(this);
}
