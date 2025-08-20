// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_response_user_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementResponseUserDetail _$SettlementResponseUserDetailFromJson(
  Map<String, dynamic> json,
) => SettlementResponseUserDetail(
  receiverNickname: json['receiverNickname'] as String,
  userSettlementList: (json['userSettlementList'] as List<dynamic>)
      .map((e) => SettlementUserDetails.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SettlementResponseUserDetailToJson(
  SettlementResponseUserDetail instance,
) => <String, dynamic>{
  'receiverNickname': instance.receiverNickname,
  'userSettlementList': instance.userSettlementList,
};
