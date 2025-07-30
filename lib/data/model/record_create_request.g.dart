// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordCreateRequest _$RecordCreateRequestFromJson(Map<String, dynamic> json) =>
    RecordCreateRequest(
      travelId: (json['travelId'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      recordTime: json['recordTime'] as String,
    );

Map<String, dynamic> _$RecordCreateRequestToJson(
  RecordCreateRequest instance,
) => <String, dynamic>{
  'travelId': instance.travelId,
  'title': instance.title,
  'content': instance.content,
  'recordTime': instance.recordTime,
};
