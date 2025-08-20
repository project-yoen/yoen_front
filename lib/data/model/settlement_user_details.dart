import 'package:json_annotation/json_annotation.dart';

part 'settlement_user_details.g.dart';

@JsonSerializable()
class SettlementUserDetails {
  final String senderNickname;
  final int? paymentId;
  final String? paymentName;
  final int amount;
  final bool? isPaid;
  final String? payTime;

  SettlementUserDetails({
    required this.senderNickname,
    required this.amount,
    this.isPaid,
    this.payTime,
    this.paymentId,
    this.paymentName,
  });

  factory SettlementUserDetails.fromJson(Map<String, dynamic> json) =>
      _$SettlementUserDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementUserDetailsToJson(this);
}
