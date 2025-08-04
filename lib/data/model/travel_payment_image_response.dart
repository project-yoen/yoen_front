import 'package:json_annotation/json_annotation.dart';

part 'travel_payment_image_response.g.dart';

@JsonSerializable()
class TravelPaymentImageResponse {
  final int travelRecordImageId;
  final String imageUrl;

  TravelPaymentImageResponse({
    required this.travelRecordImageId,
    required this.imageUrl,
  });

  factory TravelPaymentImageResponse.fromJson(Map<String, dynamic> json) =>
      _$TravelPaymentImageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TravelPaymentImageResponseToJson(this);
}
