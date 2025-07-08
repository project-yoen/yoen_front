// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    RegisterResponse(
      userId: (json['userId'] as num?)?.toInt(),
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      birthday: json['birthday'] as String?,
    );

Map<String, dynamic> _$RegisterResponseToJson(RegisterResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'gender': instance.gender,
      'birthday': instance.birthday,
    };
