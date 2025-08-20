import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/settlement_user_details.dart';

part 'settlement_response_user_detail.g.dart';

@JsonSerializable()
class SettlementResponseUserDetail {
  final String receiverNickname;
  final List<SettlementUserDetails> userSettlementList;

  SettlementResponseUserDetail({
    required this.receiverNickname,
    required this.userSettlementList,
  });

  factory SettlementResponseUserDetail.fromJson(Map<String, dynamic> json) =>
      _$SettlementResponseUserDetailFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementResponseUserDetailToJson(this);
}
