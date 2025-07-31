import 'package:json_annotation/json_annotation.dart';

part 'travel_record_image_response.g.dart';

@JsonSerializable()
class TravelRecordImageResponse {
  final int travelRecordImageId;
  final String imageUrl;

  TravelRecordImageResponse({
    required this.travelRecordImageId,
    required this.imageUrl,
  });

  factory TravelRecordImageResponse.fromJson(Map<String, dynamic> json) =>
      _$TravelRecordImageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TravelRecordImageResponseToJson(this);
}
