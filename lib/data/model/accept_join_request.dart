import 'package:json_annotation/json_annotation.dart';

part 'accept_join_request.g.dart';

@JsonSerializable()
class AcceptJoinRequest {
  final int travelJoinRequestId;
  final String role;

  AcceptJoinRequest({required this.travelJoinRequestId, required this.role});

  factory AcceptJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$AcceptJoinRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AcceptJoinRequestToJson(this);
}
