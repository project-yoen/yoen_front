import 'package:json_annotation/json_annotation.dart';

part 'travel_profile_image.g.dart';

@JsonSerializable()
class TravelProfileImage {
  final int travelId;
  final int recordImageId;

  TravelProfileImage({required this.travelId, required this.recordImageId});

  factory TravelProfileImage.fromJson(Map<String, dynamic> json) =>
      _$TravelProfileImageFromJson(json);

  Map<String, dynamic> toJson() => _$TravelProfileImageToJson(this);
}
