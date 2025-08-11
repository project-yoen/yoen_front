import 'package:flutter/material.dart';

class SettlementItem {
  final TextEditingController nameController;
  final TextEditingController amountController;

  /// 참여자
  List<int> travelUserIds;
  List<String> travelUserNames;

  /// 사람 기준 정산 완료 상태: 정산 완료한 userId 집합
  Set<int> settledUserIds;

  /// (구) 항목 기준 - 유지하되 직접 사용하지 않음. 필요 시衍生값으로 대체
  bool isPaid;

  SettlementItem({
    required this.nameController,
    required this.amountController,
    this.travelUserIds = const [],
    this.travelUserNames = const [],
    Set<int>? settledUserIds,
    this.isPaid = false,
  }) : settledUserIds = settledUserIds ?? <int>{};

  /// 완료 인원 수
  int get settledCount =>
      settledUserIds.intersection(travelUserIds.toSet()).length;

  /// 모든 참여자 완료 여부(衍生)
  bool get allSettled =>
      travelUserIds.isNotEmpty && settledCount == travelUserIds.length;
}
