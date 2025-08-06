import 'package:json_annotation/json_annotation.dart';

part 'travel_detail_response.g.dart';

@JsonSerializable()
class TravelDetailResponse {
  final int numOfPeople;
  final int numOfJoinedPeople;
  final String nation;
  final int sharedFund;
  final String travelName;
  final String startDate;
  final String endDate;
  final String? travelImageUrl;

  TravelDetailResponse({
    required this.numOfPeople,
    required this.numOfJoinedPeople,
    required this.nation,
    required this.sharedFund,
    required this.travelName,
    required this.startDate,
    required this.endDate,
    this.travelImageUrl,
  });

  factory TravelDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$TravelDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TravelDetailResponseToJson(this);
}
