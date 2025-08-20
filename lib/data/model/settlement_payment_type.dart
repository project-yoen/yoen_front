import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/enums/payment_type.dart';
import 'package:yoen_front/data/model/settlement_response_user_detail.dart';

part 'settlement_payment_type.g.dart';

@JsonSerializable()
class SettlementPaymentType {
  final PaymentType paymentType;
  final List<SettlementResponseUserDetail> settlementList;
  SettlementPaymentType({
    required this.paymentType,
    required this.settlementList,
  });

  factory SettlementPaymentType.fromJson(Map<String, dynamic> json) =>
      _$SettlementPaymentTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementPaymentTypeToJson(this);
}
