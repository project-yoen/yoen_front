import 'package:json_annotation/json_annotation.dart';

part 'record_create_request.g.dart';

@JsonSerializable()
class RecordCreateRequest {
  final int travelId;
  final String title;
  final String content;
  final String recordTime;

  RecordCreateRequest({
    required this.travelId,
    required this.title,
    required this.content,
    required this.recordTime,
  });

  factory RecordCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RecordCreateRequestToJson(this);
}
