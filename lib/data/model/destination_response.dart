import 'package:json_annotation/json_annotation.dart';

part 'destination_response.g.dart';

@JsonSerializable()
class DestinationResponse {
  final int destinationId;
  final String nation;
  final String destinationName;

  DestinationResponse({
    required this.destinationId,
    required this.nation,
    required this.destinationName,
  });

  factory DestinationResponse.fromJson(Map<String, dynamic> json) =>
      _$DestinationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DestinationResponseToJson(this);
}
