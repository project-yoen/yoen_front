import 'package:json_annotation/json_annotation.dart';

part 'travel_create_response.g.dart';

@JsonSerializable()
class TravelCreateResponse {
  final int travelId;
  final String travelName;
  final String startDate;
  final String endDate;
  final String nation;
  final int numOfPeople;
  final int numOfJoinedPeople;
  final int? sharedFund;

  TravelCreateResponse({
    required this.travelId,
    required this.travelName,
    required this.startDate,
    required this.endDate,
    required this.nation,
    required this.numOfPeople,
    required this.numOfJoinedPeople,
    this.sharedFund,
  });

  factory TravelCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$TravelCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TravelCreateResponseToJson(this);
}
