// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DestinationResponse _$DestinationResponseFromJson(Map<String, dynamic> json) =>
    DestinationResponse(
      destinationId: (json['destinationId'] as num).toInt(),
      nation: json['nation'] as String,
      destinationName: json['destinationName'] as String,
    );

Map<String, dynamic> _$DestinationResponseToJson(
  DestinationResponse instance,
) => <String, dynamic>{
  'destinationId': instance.destinationId,
  'nation': instance.nation,
  'destinationName': instance.destinationName,
};
