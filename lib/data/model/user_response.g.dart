// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
  userId: (json['userId'] as num?)?.toInt(),
  email: json['email'] as String?,
  gender: json['gender'] as String?,
  birthday: json['birthday'] as String?,
);

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'gender': instance.gender,
      'birthday': instance.birthday,
    };
