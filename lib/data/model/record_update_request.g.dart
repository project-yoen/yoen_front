// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordUpdateRequest _$RecordUpdateRequestFromJson(Map<String, dynamic> json) =>
    RecordUpdateRequest(
      travelRecordId: (json['travelRecordId'] as num).toInt(),
      travelId: (json['travelId'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String?,
      recordTime: json['recordTime'] as String,
      removeImageIds: (json['removeImageIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$RecordUpdateRequestToJson(
  RecordUpdateRequest instance,
) => <String, dynamic>{
  'travelRecordId': instance.travelRecordId,
  'travelId': instance.travelId,
  'title': instance.title,
  'content': instance.content,
  'recordTime': instance.recordTime,
  'removeImageIds': instance.removeImageIds,
};
