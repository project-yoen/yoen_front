import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/travel_record_image_response.dart';

part 'record_response.g.dart';

@JsonSerializable()
class RecordResponse {
  final int travelRecordId;
  final String title;
  final String content;
  final List<TravelRecordImageResponse> images;
  final String recordTime; // recordTime 추가
  final String travelNickName; //작성자

  RecordResponse({
    required this.travelRecordId,
    required this.title,
    required this.content,
    required this.images,
    required this.recordTime, // recordTime 추가
    required this.travelNickName,
  });

  factory RecordResponse.fromJson(Map<String, dynamic> json) =>
      _$RecordResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RecordResponseToJson(this);
}
