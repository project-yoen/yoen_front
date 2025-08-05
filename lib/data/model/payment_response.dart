import 'package:json_annotation/json_annotation.dart';

part 'payment_response.g.dart';

@JsonSerializable()
class PaymentResponse {
  final int paymentId;
  final String paymentName;
  final int categoryId;
  final String payerType;
  final String payTime;
  final String paymentMethod;
  final String paymentType;
  final int paymentAccount;

  PaymentResponse({
    required this.paymentId,
    required this.paymentName,
    required this.categoryId,
    required this.payerType,
    required this.payTime,
    required this.paymentMethod,
    required this.paymentType,
    required this.paymentAccount,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentResponseToJson(this);
}
