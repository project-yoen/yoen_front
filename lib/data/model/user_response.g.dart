// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
  userId: (json['userId'] as num?)?.toInt(),
  name: json['name'] as String?,
  email: json['email'] as String?,
  gender: json['gender'] as String?,
  nickname: json['nickname'] as String?,
  birthday: json['birthday'] as String?,
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'gender': instance.gender,
      'nickname': instance.nickname,
      'birthday': instance.birthday,
      'imageUrl': instance.imageUrl,
    };
