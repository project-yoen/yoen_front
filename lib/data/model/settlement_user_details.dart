import 'package:json_annotation/json_annotation.dart';

part 'settlement_user_details.g.dart';

@JsonSerializable()
class SettlementUserDetails {
  final String senderNickname;
  final int? paymentId;
  final String? paymentName;
  final String? settlementName;
  final int amount;
  final bool? isPaid;
  final String? payTime;

  SettlementUserDetails({
    required this.senderNickname,
    this.paymentId,
    this.paymentName,
    this.settlementName,
    required this.amount,
    this.isPaid,
    this.payTime,
  });

  factory SettlementUserDetails.fromJson(Map<String, dynamic> json) =>
      _$SettlementUserDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementUserDetailsToJson(this);
}
