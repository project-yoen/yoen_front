import 'package:json_annotation/json_annotation.dart';

part 'travel_response.g.dart';

@JsonSerializable()
class TravelResponse {
  final int travelId;
  final int numOfPeople;
  final String travelName;
  final String startDate;
  final String endDate;
  final String nation;
  final String? travelImageUrl;

  TravelResponse({
    required this.travelId,
    required this.numOfPeople,
    required this.travelName,
    required this.startDate,
    required this.endDate,
    required this.nation,
    this.travelImageUrl,
  });

  factory TravelResponse.fromJson(Map<String, dynamic> json) =>
      _$TravelResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TravelResponseToJson(this);
}
