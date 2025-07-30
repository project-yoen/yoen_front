import 'package:json_annotation/json_annotation.dart';

part 'record_create_response.g.dart';

@JsonSerializable()
class RecordCreateResponse {
  // TODO: API 응답에 맞게 필드 정의
  RecordCreateResponse();

  factory RecordCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$RecordCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RecordCreateResponseToJson(this);
}
