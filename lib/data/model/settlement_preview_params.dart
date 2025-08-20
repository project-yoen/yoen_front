class SettlementPreviewParams {
  final int travelId;
  final bool includePreUseAmount;
  final bool includeSharedAmount;
  final bool includeRecordedAmount;
  final DateTime startAt;
  final DateTime endAt;

  const SettlementPreviewParams({
    required this.travelId,
    required this.includePreUseAmount,
    required this.includeSharedAmount,
    required this.includeRecordedAmount,
    required this.startAt,
    required this.endAt,
  });

  Map<String, dynamic> toQuery() => {
    'preUseAmount': includePreUseAmount,
    'sharedFund': includeSharedAmount,
    'recordedAmount': includeRecordedAmount,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
  };
}
