import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/model/settlement_result_response.dart';

import '../model/settlement_preview_params.dart';

final dialogOpenProvider = StateProvider<bool>((ref) => false);

final overviewTabIndexProvider = StateProvider<int>((ref) => 0);

final settlementPreviewProvider = FutureProvider.autoDispose
    .family<SettlementResultResponse, SettlementPreviewParams>((
      ref,
      params,
    ) async {
      final api = ref.read(apiServiceProvider); // 이미 쓰고 있는 API 클라이언트
      final res = await api.getSettlement(
        params.travelId,
        params.includePreUseAmount,
        params.includeSharedAmount,
        params.includeRecordedAmount,
        params.startAt.toIso8601String(),
        params.endAt.toIso8601String(),
      );
      return res.data!; // ApiResponse<T> 구조면 .data 꺼내기
    });
