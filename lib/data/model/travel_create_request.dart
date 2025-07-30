import 'package:json_annotation/json_annotation.dart';

part 'travel_create_request.g.dart';

@JsonSerializable()
class TravelCreateRequest {
  final String travelName;
  final int numOfPeople;
  final String nation;
  final String startDate;
  final String endDate;
  final List<int> destinationIds;

  TravelCreateRequest({
    required this.travelName,
    required this.numOfPeople,
    required this.nation,
    required this.startDate,
    required this.endDate,
    required this.destinationIds,
  });

  factory TravelCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$TravelCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TravelCreateRequestToJson(this);
}
