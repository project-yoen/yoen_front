// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordResponse _$RecordResponseFromJson(Map<String, dynamic> json) =>
    RecordResponse(
      title: json['title'] as String,
      content: json['content'] as String,
      images: (json['images'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      recordTime: json['recordTime'] as String,
      travelNickName: json['travelNickName'] as String,
    );

Map<String, dynamic> _$RecordResponseToJson(RecordResponse instance) =>
    <String, dynamic>{
      'title': instance.title,
      'content': instance.content,
      'images': instance.images,
      'recordTime': instance.recordTime,
      'travelNickName': instance.travelNickName,
    };
