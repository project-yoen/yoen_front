import 'package:json_annotation/json_annotation.dart';

part 'settlement_request.g.dart';

@JsonSerializable()
class SettlementRequest {
  final bool includePreUseAmount; // 사전 사용 금액 포함 여부
  final bool includeSharedFund; // 공금 포함 여부
  final bool includeRecordedAmount; // 기록된 금액 포함 여부
  final String startAt; // ISO-8601
  final String endAt; // ISO-8601

  SettlementRequest({
    required this.includePreUseAmount,
    required this.includeSharedFund,
    required this.includeRecordedAmount,
    required this.startAt,
    required this.endAt,
  });

  factory SettlementRequest.fromJson(Map<String, dynamic> json) =>
      _$SettlementRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementRequestToJson(this);
}
