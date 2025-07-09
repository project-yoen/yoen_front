// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      userId: (json['userId'] as num?)?.toInt(),
      email: json['email'] as String?,
      password: json['password'] as String?,
      nickname: json['nickname'] as String?,
      gender: json['gender'] as String?,
      birthday: json['birthday'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'password': instance.password,
      'nickname': instance.nickname,
      'gender': instance.gender,
      'birthday': instance.birthday,
    };
