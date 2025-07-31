import 'package:json_annotation/json_annotation.dart';

part 'record_response.g.dart';

@JsonSerializable()
class RecordResponse {
  final String title;
  final String content;
  final List<String> images;

  RecordResponse({
    required this.title,
    required this.content,
    required this.images,
  });

  factory RecordResponse.fromJson(Map<String, dynamic> json) =>
      _$RecordResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RecordResponseToJson(this);
}
