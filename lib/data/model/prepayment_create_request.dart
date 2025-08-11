import 'package:json_annotation/json_annotation.dart';

part 'prepayment_create_request.g.dart';

@JsonSerializable()
class PrepaymentCreateRequest {
  final int travelId;
  final int categoryId;
  final int payerTravelUserId;
  final String paymentName;
  final int paymentAccount;
  final String currency;
  final List<SettlementParticipantRequestDto> settlementList;

  PrepaymentCreateRequest({
    required this.travelId,
    required this.categoryId,
    required this.payerTravelUserId,
    required this.paymentName,
    required this.paymentAccount,
    required this.currency,
    required this.settlementList,
  });

  factory PrepaymentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PrepaymentCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PrepaymentCreateRequestToJson(this);
}

@JsonSerializable()
class SettlementParticipantRequestDto {
  final int travelUserId;
  final bool isPaid;

  SettlementParticipantRequestDto({
    required this.travelUserId,
    required this.isPaid,
  });

  factory SettlementParticipantRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SettlementParticipantRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SettlementParticipantRequestDtoToJson(this);
}
