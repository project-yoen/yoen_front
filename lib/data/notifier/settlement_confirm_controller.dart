// settlement_confirm_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/settlement_preview_params.dart';
import '../repository/settlement_repository.dart';

class SettlementConfirmController extends AutoDisposeAsyncNotifier<void> {
  late final SettlementRepository _repo;

  @override
  void build() {
    // 동기 build (async 금지)
    _repo = ref.read(settlementRepositoryProvider);
  }

  Future<void> confirm(SettlementPreviewParams params) async {
    state = const AsyncLoading(); // 호출 시에만 로딩
    state = await AsyncValue.guard(() => _repo.doSettlement(params));
  }
}

final settlementConfirmControllerProvider =
    AutoDisposeAsyncNotifierProvider<SettlementConfirmController, void>(
      SettlementConfirmController.new,
    );
