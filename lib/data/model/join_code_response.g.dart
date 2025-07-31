// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_code_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinCodeResponse _$JoinCodeResponseFromJson(Map<String, dynamic> json) =>
    JoinCodeResponse(
      code: json['code'] as String,
      expiredAt: json['expiredAt'] as String,
    );

Map<String, dynamic> _$JoinCodeResponseToJson(JoinCodeResponse instance) =>
    <String, dynamic>{'code': instance.code, 'expiredAt': instance.expiredAt};
