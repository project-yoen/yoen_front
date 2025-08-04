import 'package:json_annotation/json_annotation.dart';

part 'payment_create_response.g.dart';

@JsonSerializable()
class PaymentCreateResponse {
  // TODO: API 응답에 맞게 필드 정의
  PaymentCreateResponse();

  factory PaymentCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateResponseToJson(this);
}
