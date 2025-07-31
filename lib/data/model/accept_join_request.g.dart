// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_join_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptJoinRequest _$AcceptJoinRequestFromJson(Map<String, dynamic> json) =>
    AcceptJoinRequest(
      travelJoinRequestId: (json['travelJoinRequestId'] as num).toInt(),
      role: json['role'] as String,
    );

Map<String, dynamic> _$AcceptJoinRequestToJson(AcceptJoinRequest instance) =>
    <String, dynamic>{
      'travelJoinRequestId': instance.travelJoinRequestId,
      'role': instance.role,
    };
