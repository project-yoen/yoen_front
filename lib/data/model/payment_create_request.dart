import 'package:json_annotation/json_annotation.dart';

part 'payment_create_request.g.dart';

@JsonSerializable()
class PaymentCreateRequest {
  final int travelId;
  final String title;
  final String content;
  final String recordTime;

  PaymentCreateRequest({
    required this.travelId,
    required this.title,
    required this.content,
    required this.recordTime,
  });

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateRequestToJson(this);
}
