// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRequest _$UserRequestFromJson(Map<String, dynamic> json) => UserRequest(
  userId: (json['userId'] as num?)?.toInt(),
  email: json['email'] as String?,
  password: json['password'] as String?,
  gender: json['gender'] as String?,
  birthday: json['birthday'] as String?,
);

Map<String, dynamic> _$UserRequestToJson(UserRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'password': instance.password,
      'gender': instance.gender,
      'birthday': instance.birthday,
    };
