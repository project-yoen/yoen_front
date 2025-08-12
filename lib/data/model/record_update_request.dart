import 'package:json_annotation/json_annotation.dart';
import 'package:yoen_front/data/model/travel_record_image_response.dart';

part 'record_update_request.g.dart';

@JsonSerializable()
class RecordUpdateRequest {
  final int travelRecordId;
  final int travelId;
  final String title;
  final String content;
  final String recordTime; // recordTime 추가
  final List<int> removeImageIds;

  RecordUpdateRequest({
    required this.travelRecordId,
    required this.travelId,
    required this.title,
    required this.content,
    required this.recordTime, // recordTime 추가
    required this.removeImageIds,
  });

  factory RecordUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RecordUpdateRequestToJson(this);
}
