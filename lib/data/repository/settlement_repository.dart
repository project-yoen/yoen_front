// lib/data/repository/settlement_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/api/api_service.dart';
import 'package:yoen_front/data/model/settlement_preview_params.dart';

abstract class SettlementRepository {
  Future<void> doSettlement(SettlementPreviewParams params);
}

class SettlementRepositoryImpl implements SettlementRepository {
  final ApiService _apiService;
  SettlementRepositoryImpl(this._apiService);

  @override
  Future<void> doSettlement(SettlementPreviewParams p) async {
    await _apiService.doSettlement(
      p.travelId,
      p.includePreUseAmount,
      p.includeSharedAmount,
      p.includeRecordedAmount,
      p.startAt.toIso8601String(),
      p.endAt.toIso8601String(),
    );
  }
}

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  final api = ref.read(apiServiceProvider);
  return SettlementRepositoryImpl(api);
});
