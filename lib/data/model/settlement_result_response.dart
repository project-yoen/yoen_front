import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/settlement_payment_type.dart';
import 'package:yoen_front/data/model/settlement_response_user_detail.dart';

part 'settlement_result_response.g.dart';

@JsonSerializable()
class SettlementResultResponse {
  final List<SettlementResponseUserDetail> userSettlementList;
  final List<SettlementPaymentType> paymentTypeList;

  SettlementResultResponse({
    required this.userSettlementList,
    required this.paymentTypeList,
  });

  factory SettlementResultResponse.fromJson(Map<String, dynamic> json) =>
      _$SettlementResultResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementResultResponseToJson(this);
}
