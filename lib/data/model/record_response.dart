import 'package:json_annotation/json_annotation.dart';

part 'record_response.g.dart';

@JsonSerializable()
class RecordResponse {
  final String title;
  final String content;
  final List<String> images;
  final String recordTime; // recordTime 추가
  final String travelNickName; //작성자

  RecordResponse({
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
