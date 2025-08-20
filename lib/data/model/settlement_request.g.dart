// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementRequest _$SettlementRequestFromJson(Map<String, dynamic> json) =>
    SettlementRequest(
      includePreUseAmount: json['includePreUseAmount'] as bool,
      includeSharedFund: json['includeSharedFund'] as bool,
      includeRecordedAmount: json['includeRecordedAmount'] as bool,
      startAt: json['startAt'] as String,
      endAt: json['endAt'] as String,
    );

Map<String, dynamic> _$SettlementRequestToJson(SettlementRequest instance) =>
    <String, dynamic>{
      'includePreUseAmount': instance.includePreUseAmount,
      'includeSharedFund': instance.includeSharedFund,
      'includeRecordedAmount': instance.includeRecordedAmount,
      'startAt': instance.startAt,
      'endAt': instance.endAt,
    };
