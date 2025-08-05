import 'package:json_annotation/json_annotation.dart';

part 'payment_response.g.dart';

@JsonSerializable()
class PaymentResponse {
  final int paymentId;
  final String paymentName;
  final String categoryName;
  final String payer;
  final String payTime;
  final int paymentAccount;

  PaymentResponse({
    required this.paymentId,
    required this.paymentName,
    required this.categoryName,
    required this.payer,
    required this.payTime,
    required this.paymentAccount,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentResponseToJson(this);
}
