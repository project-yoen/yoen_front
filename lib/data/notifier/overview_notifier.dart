// lib/data/notifier/overview_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 공용 Status

// 타임라인 아이템 모델(Record/Payment를 둘 다 담을 수 있는 타입)
import 'package:yoen_front/data/model/timeline_item.dart';

// 도메인 상태
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';

import '../enums/status.dart';

enum OverviewStatus { initial, loading, success, error }

class OverviewState {
  final OverviewStatus status;
  final List<TimelineItem> items;
  final String? errorMessage;
  final int? lastTravelId;
  final DateTime? lastDate;

  const OverviewState({
    this.status = OverviewStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.lastTravelId,
    this.lastDate,
  });

  OverviewState copyWith({
    OverviewStatus? status,
    List<TimelineItem>? items,
    String? errorMessage,
    int? lastTravelId,
    DateTime? lastDate,
  }) {
    return OverviewState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      lastTravelId: lastTravelId ?? this.lastTravelId,
      lastDate: lastDate ?? this.lastDate,
    );
  }
}

class OverviewNotifier extends StateNotifier<OverviewState> {
  OverviewNotifier(this.ref) : super(const OverviewState()) {
    // 두 도메인 상태 변화를 모두 구독 → 변경 시마다 타임라인 재조립
    ref.listen<RecordState>(recordNotifierProvider, (prev, next) {
      _rebuildFromSources();
    });
    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      _rebuildFromSources();
    });
  }

  final Ref ref;

  /// 최초/재조회 트리거: 실제 fetch는 각 도메인 Notifier에게 위임
  Future<void> fetchTimeline(int travelId, DateTime date) async {
    // 로딩 표시 & 컨텍스트 저장
    state = state.copyWith(
      status: OverviewStatus.loading,
      lastTravelId: travelId,
      lastDate: date,
    );

    // 병렬 fetch
    await Future.wait([
      ref.read(recordNotifierProvider.notifier).getRecords(travelId, date),
      ref
          .read(paymentNotifierProvider.notifier)
          .getPayments(travelId, date, null),
    ]);

    // 결과는 각 notifier가 state 갱신 → 아래 listen에서 자동 호출되지만
    // 초회 시점 보장 위해 한 번 더 수동 재조립
    _rebuildFromSources();
  }

  Future<void> refreshLast() async {
    final t = state.lastTravelId, d = state.lastDate;
    if (t == null || d == null) return;
    await fetchTimeline(t, d);
  }

  void _rebuildFromSources() {
    final r = ref.read(recordNotifierProvider);
    final p = ref.read(paymentNotifierProvider);

    // 종합 로딩/에러 판단
    final anyLoading =
        r.getStatus == Status.loading || p.getStatus == Status.loading;
    final anyError = r.getStatus == Status.error || p.getStatus == Status.error;

    if (anyLoading) {
      state = state.copyWith(status: OverviewStatus.loading);
      return; // 직전 items 유지
    }

    if (anyError) {
      state = state.copyWith(
        status: OverviewStatus.error,
        errorMessage: r.errorMessage ?? p.errorMessage ?? '알 수 없는 오류',
      );
      return;
    }

    // 성공: 두 목록을 합쳐 타임라인 구성
    final items = <TimelineItem>[
      for (final rec in r.records)
        TimelineItem(
          type: TimelineItemType.record,
          timestamp: DateTime.parse(rec.recordTime),
          data: rec,
        ),
      for (final pay in p.allPayments)
        TimelineItem(
          type: TimelineItemType.payment,
          timestamp: DateTime.parse(pay.payTime),
          data: pay,
        ),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    state = state.copyWith(status: OverviewStatus.success, items: items);
  }
}

final overviewNotifierProvider =
    StateNotifierProvider<OverviewNotifier, OverviewState>((ref) {
      return OverviewNotifier(ref);
    });
