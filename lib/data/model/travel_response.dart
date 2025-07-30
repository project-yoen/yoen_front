import 'package:json_annotation/json_annotation.dart';

part 'travel_response.g.dart';

@JsonSerializable()
class TravelResponse {
  final int travelId;
  final String travelName;
  final String startDate;
  final String? imageUrl;

  TravelResponse({
    required this.travelId,
    required this.travelName,
    required this.startDate,
    this.imageUrl,
  });

  factory TravelResponse.fromJson(Map<String, dynamic> json) =>
      _$TravelResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TravelResponseToJson(this);
}
