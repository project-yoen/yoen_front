import 'package:json_annotation/json_annotation.dart';

part 'payment_image_response.g.dart';

@JsonSerializable()
class PaymentImageResponse {
  final int paymentImageId;
  final String imageUrl;

  PaymentImageResponse({required this.paymentImageId, required this.imageUrl});

  factory PaymentImageResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentImageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentImageResponseToJson(this);
}
